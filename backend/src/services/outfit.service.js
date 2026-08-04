const SEASON_TO_THEME = {
  summer: ['light', 'fresh', 'bright'],
  winter: ['warm', 'cozy', 'structured'],
  spring: ['soft', 'airy', 'colorful'],
  autumn: ['earthy', 'layered', 'balanced'],
};

const COLOR_NEUTRALS = new Set(['white', 'black', 'gray', 'grey', 'cream', 'beige', 'tan', 'navy', 'brown', 'silver']);

const normalize = (value) => (value ?? '').toString().trim().toLowerCase();

const normalizeLaundryStatus = (value) => normalize(value);

const normalizeItemCategory = (item) => {
  const category = normalize(item?.category);
  const subCategory = normalize(item?.subCategory);

  if (['top', 'tops', 'shirt', 'tee', 'blouse', 'sweater', 'dress'].includes(category)) return 'tops';
  if (['bottom', 'bottoms', 'pants', 'trouser', 'trousers', 'jeans', 'shorts', 'skirt'].includes(category)) return 'bottoms';
  if (['shoe', 'shoes', 'footwear', 'sneaker', 'sneakers', 'boot', 'boots'].includes(category) || ['shoe', 'shoes', 'footwear'].includes(subCategory)) return 'footwear';
  if (['outerwear', 'jacket', 'coat', 'blazer', 'vest'].includes(category) || subCategory.includes('outer')) return 'outerwear';
  if (['accessory', 'accessories', 'belt', 'hat', 'scarf', 'sunglasses', 'jewelry'].includes(category) || subCategory.includes('access')) return 'accessories';
  if (['bag', 'bags', 'backpack', 'tote', 'crossbody'].includes(category) || subCategory.includes('bag')) return 'bags';
  if (['watch', 'watches'].includes(category) || subCategory.includes('watch')) return 'watches';

  if (category === 'other' && subCategory.includes('bag')) return 'bags';
  if (category === 'other' && subCategory.includes('watch')) return 'watches';

  return 'accessories';
};

const isSuitableForSeason = (item, season) => {
  if (!item?.season || item.season === 'all-season') return true;
  return normalize(item.season) === normalize(season);
};

const isClean = (item) => {
  const laundry = normalizeLaundryStatus(item?.laundryStatus);
  return laundry === '' || !['dirty', 'washing', 'repair', 'in-use'].includes(laundry);
};

const isUsableWardrobeItem = (item) => {
  if (!item || !item.name || !String(item.name).trim()) return false;
  if (item.isDeleted || item.deleted || item.deletedAt) return false;
  if (item.userId && String(item.userId).trim() === '') return false;
  if (!isClean(item)) return false;
  return true;
};

const isNotDuplicate = (selected, candidate) => {
  if (!candidate) return false;
  return !selected.some((item) => normalize(item?._id ?? item?.name) === normalize(candidate?._id ?? candidate?.name));
};

const colorCompatibility = (topColor, bottomColor) => {
  const top = normalize(topColor);
  const bottom = normalize(bottomColor);

  if (!top || !bottom) return true;
  if (COLOR_NEUTRALS.has(top) || COLOR_NEUTRALS.has(bottom)) return true;

  const clashes = [
    ['red', 'green'],
    ['blue', 'orange'],
    ['purple', 'yellow'],
  ];

  return !clashes.some(([a, b]) => (top === a && bottom === b) || (top === b && bottom === a));
};

const scoreItem = (item, request, selected) => {
  let score = 0;
  const season = normalize(request.season);
  const group = normalizeItemCategory(item);

  if (item.favorite) score += 5;
  if (isSuitableForSeason(item, season)) score += 4;
  if (isClean(item)) score += 3;

  if (item.lastWorn) {
    const lastWorn = new Date(item.lastWorn);
    const now = new Date();
    const ageDays = Math.max(1, (now - lastWorn) / (1000 * 60 * 60 * 24));
    score += Math.min(8, Math.floor(ageDays / 3));
  } else {
    score += 4;
  }

  if (typeof item.wearCount === 'number') {
    score += Math.max(0, 4 - item.wearCount);
  }

  if (selected.some((picked) => normalize(picked?._id ?? picked?.name) === normalize(item?._id ?? item?.name))) {
    score -= 100;
  }

  if (group === 'tops' && normalize(request.occasion) === 'office') score += 2;
  if (group === 'bottoms' && normalize(request.occasion) === 'office') score += 1;
  if (group === 'outerwear' && normalize(request.weather) === 'cold') score += 3;
  if (group === 'footwear' && normalize(request.weather) === 'rainy') score += 2;
  if (group === 'tops' && normalize(request.weather) === 'hot') score += 2;
  if (normalize(item?.season || 'all-season') === normalize(request.season) || normalize(item?.season || 'all-season') === 'all-season') score += 2;

  return score;
};

const pickBestItem = ({ items, category, request, selected = [] }) => {
  const candidates = items
    .filter((item) => normalizeItemCategory(item) === category)
    .filter(isUsableWardrobeItem)
    .filter((item) => isSuitableForSeason(item, request.season))
    .filter((item) => isNotDuplicate(selected, item))
    .sort((a, b) => scoreItem(b, request, selected) - scoreItem(a, request, selected));

  return candidates[0] || null;
};

const toRecommendedItem = (item, overrideCategory) => {
  if (!item || !item.name) return null;

  const category = overrideCategory || normalizeItemCategory(item);
  return {
    _id: item._id ? String(item._id) : '',
    name: item.name,
    color: item.color || '',
    category: category === 'tops' ? 'Top' : category === 'bottoms' ? 'Bottom' : category === 'footwear' ? 'Footwear' : category === 'outerwear' ? 'Outerwear' : category === 'accessories' ? 'Accessories' : category === 'bags' ? 'Bag' : category === 'watches' ? 'Watch' : 'Accessory',
    favorite: Boolean(item.favorite),
    lastWorn: item.lastWorn ? new Date(item.lastWorn).toISOString() : null,
    imageUrl: item.imageUrl || '',
  };
};

const buildWardrobeSummary = (wardrobe = []) => {
  const groups = { tops: [], bottoms: [], footwear: [], outerwear: [], accessories: [], bags: [], watches: [] };

  for (const item of wardrobe) {
    if (!isUsableWardrobeItem(item)) continue;
    const group = normalizeItemCategory(item);
    if (groups[group]) {
      groups[group].push({
        _id: item._id ? String(item._id) : '',
        name: item.name,
        color: item.color || '',
        season: item.season || 'all-season',
        favorite: Boolean(item.favorite),
        lastWorn: item.lastWorn || null,
        category: item.category || group,
        subCategory: item.subCategory || '',
        laundryStatus: item.laundryStatus || 'clean',
      });
    }
  }

  return groups;
};

const findWardrobeItemByName = (name, wardrobe = []) => {
  if (!name) return null;
  const target = normalize(name);
  return wardrobe.find((item) => normalize(item.name) === target) || null;
};

const ensureRealWardrobeItems = (rawRecommendation, wardrobe = []) => {
  const normalized = { ...rawRecommendation };
  const selected = [];

  for (const key of ['top', 'bottom', 'footwear', 'outerwear', 'accessories', 'bag', 'watch']) {
    const value = normalized[key];
    if (!value) {
      normalized[key] = null;
      continue;
    }

    const match = findWardrobeItemByName(value, wardrobe);
    if (match) {
      normalized[key] = match.name;
      selected.push(match);
    } else {
      normalized[key] = null;
    }
  }

  const recommendedItems = selected
    .map((item) => toRecommendedItem(item, normalizeItemCategory(item)))
    .filter(Boolean);

  normalized.recommendedItems = recommendedItems;
  return normalized;
};

export const buildOutfitRecommendation = ({ wardrobe = [], request = {} }) => {
  if (!Array.isArray(wardrobe) || wardrobe.length === 0) {
    return {
      top: null,
      bottom: null,
      footwear: null,
      accessories: null,
      outerwear: null,
      bag: null,
      watch: null,
      confidence: 0,
      reason: 'No clean wardrobe items were found for this request.',
      recommendedItems: [],
    };
  }

  const safeRequest = {
    occasion: request.occasion || 'casual',
    weather: request.weather || 'sunny',
    temperature: request.temperature || 24,
    season: request.season || 'all-season',
  };

  const wardrobeItems = wardrobe.filter(isUsableWardrobeItem);
  if (wardrobeItems.length === 0) {
    return {
      top: null,
      bottom: null,
      footwear: null,
      accessories: null,
      outerwear: null,
      bag: null,
      watch: null,
      confidence: 0,
      reason: 'No clean wardrobe items are available right now.',
      recommendedItems: [],
    };
  }

  const selected = [];
  const top = pickBestItem({ items: wardrobeItems, category: 'tops', request: safeRequest, selected });
  if (top) selected.push(top);

  const bottom = pickBestItem({ items: wardrobeItems, category: 'bottoms', request: safeRequest, selected });
  if (bottom) selected.push(bottom);

  const footwear = pickBestItem({ items: wardrobeItems, category: 'footwear', request: safeRequest, selected });
  if (footwear) selected.push(footwear);

  const outerwear = pickBestItem({ items: wardrobeItems, category: 'outerwear', request: safeRequest, selected });
  if (outerwear) selected.push(outerwear);

  const accessory = pickBestItem({ items: wardrobeItems, category: 'accessories', request: safeRequest, selected });
  if (accessory) selected.push(accessory);

  const bag = pickBestItem({ items: wardrobeItems, category: 'bags', request: safeRequest, selected });
  if (bag) selected.push(bag);

  const watch = pickBestItem({ items: wardrobeItems, category: 'watches', request: safeRequest, selected });
  if (watch) selected.push(watch);

  const topColor = normalize(top?.color || top?.secondaryColor || '');
  const bottomColor = normalize(bottom?.color || bottom?.secondaryColor || '');
  const colorOk = colorCompatibility(topColor, bottomColor);

  const recommendation = {
    top: top?.name ?? null,
    bottom: bottom?.name ?? null,
    footwear: footwear?.name ?? null,
    accessories: accessory?.name ?? null,
    outerwear: outerwear?.name ?? null,
    bag: bag?.name ?? null,
    watch: watch?.name ?? null,
    confidence: 0,
    reason: '',
    recommendedItems: [],
  };

  if (!colorOk && bottom) {
    const fallback = wardrobeItems.find((item) => normalizeItemCategory(item) === 'bottoms' && item.name !== bottom.name);
    if (fallback) {
      recommendation.bottom = fallback.name;
    }
  }

  recommendation.recommendedItems = selected
    .map((item) => toRecommendedItem(item, normalizeItemCategory(item)))
    .filter(Boolean);

  const themes = SEASON_TO_THEME[safeRequest.season] || SEASON_TO_THEME.summer;
  const theme = themes[Math.floor(Math.random() * themes.length)];
  recommendation.reason = `${safeRequest.occasion} outfit using your clean wardrobe for ${safeRequest.weather} weather with a ${theme} palette. It keeps items fresh and balanced.`;
  recommendation.confidence = Math.min(98, 60 + (top ? 8 : 0) + (bottom ? 8 : 0) + (footwear ? 7 : 0) + (accessory ? 4 : 0) + (colorOk ? 5 : 0));

  return recommendation;
};

export const generateOutfitRecommendation = async ({ wardrobe = [], request = {} }) => {
  const apiKey = process.env.GEMINI_API_KEY;

  if (apiKey) {
    try {
      const structuredWardrobe = buildWardrobeSummary(wardrobe);
      const prompt = [
        'Return JSON only.',
        'Use ONLY the clothing items provided below.',
        'Do NOT invent clothing.',
        'Do NOT generate placeholder names.',
        'Do NOT return generic labels like Classic top, Versatile bottoms, or Comfortable shoes.',
        'If there is no suitable item in the wardrobe for a category, set that value to null.',
        'Prioritize least recently worn items, then favorites, then season and occasion fit, then weather and clean laundry status.',
        'Avoid dirty items, duplicates, and recently worn items.',
        'Return an object with keys: top, bottom, footwear, outerwear, accessories, bag, watch, confidence, reason, recommendedItems.',
        'recommendedItems must be an array of real wardrobe objects with fields _id, name, and category.',
        `Request: occasion=${request.occasion || 'casual'}, weather=${request.weather || 'sunny'}, temperature=${request.temperature || 24}, season=${request.season || 'all-season'}`,
        `Wardrobe: ${JSON.stringify(structuredWardrobe)}`,
      ].join(' ');

      console.log('[OUTFIT] Gemini prompt', { prompt });

      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      });

      const rawResponse = await response.text();
      console.log('[OUTFIT] Gemini raw response', { rawResponse });

      let parsed = {};
      try {
        const candidatePayload = JSON.parse(rawResponse);
        const candidateText = candidatePayload?.candidates?.[0]?.content?.parts?.[0]?.text || rawResponse;
        parsed = JSON.parse(candidateText.replace(/```json|```/g, '').trim());
      } catch (error) {
        console.warn('[OUTFIT] Invalid Gemini JSON response', error.message);
        return buildOutfitRecommendation({ wardrobe, request });
      }

      console.log('[OUTFIT] Parsed Gemini JSON', { parsed });

      if (parsed && typeof parsed === 'object') {
        const normalized = ensureRealWardrobeItems(parsed, wardrobe);
        console.log('[OUTFIT] Recommended IDs', { ids: normalized.recommendedItems.map((item) => item._id) });
        console.log('[OUTFIT] Recommended items', { items: normalized.recommendedItems });
        return {
          ...buildOutfitRecommendation({ wardrobe, request }),
          ...normalized,
          recommendedItems: normalized.recommendedItems.length > 0 ? normalized.recommendedItems : buildOutfitRecommendation({ wardrobe, request }).recommendedItems,
        };
      }
    } catch (error) {
      console.warn('[OUTFIT] Gemini fallback failed', error.message);
    }
  }

  return buildOutfitRecommendation({ wardrobe, request });
};
