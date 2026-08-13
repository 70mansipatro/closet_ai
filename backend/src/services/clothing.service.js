import { AppError } from '../utils/appError.js';
import {
  CATEGORY_OPTIONS,
  CATEGORY_ALIASES,
  SEASON_OPTIONS,
  SEASON_ALIASES,
  STYLE_OPTIONS,
  PATTERN_OPTIONS,
  PATTERN_ALIASES,
  MATERIAL_OPTIONS,
  OCCASION_OPTIONS,
  OCCASION_ALIASES,
  WEATHER_OPTIONS,
  FIT_OPTIONS,
  FIT_ALIASES,
  LAUNDRY_STATUS_OPTIONS,
  normalizeEnumValue,
  normalizeEnumList,
} from '../constants/clothingOptions.js';

const allowedCategories = CATEGORY_OPTIONS;
const allowedSeasons = SEASON_OPTIONS;
const allowedLaundryStatuses = LAUNDRY_STATUS_OPTIONS;

const isDebug = process.env.NODE_ENV !== 'production';
const debugLog = (...args) => {
  if (isDebug) console.log(...args);
};

const toStringArray = (value) => {
  if (Array.isArray(value)) return value.filter((item) => typeof item === 'string' && item.trim());
  if (typeof value === 'string' && value.trim()) return [value.trim()];
  return [];
};

const normalizePayload = (payload = {}) => {
  const normalized = { ...payload };

  // wearCount/lastWorn are backend-owned (see services/wear.service.js) and
  // must never be settable through the create/update clothing endpoints.
  delete normalized.wearCount;
  delete normalized.lastWorn;

  if (normalized.purchasePrice !== undefined && normalized.purchasePrice !== '') {
    normalized.purchasePrice = Number(normalized.purchasePrice);
  }

  if (normalized.favorite !== undefined) {
    normalized.favorite = normalized.favorite === true || normalized.favorite === 'true';
  }

  if (normalized.aiAnalyzed !== undefined) {
    normalized.aiAnalyzed = normalized.aiAnalyzed === true || normalized.aiAnalyzed === 'true';
  }

  if (normalized.purchaseDate) {
    normalized.purchaseDate = new Date(normalized.purchaseDate);
  }

  if (normalized.category) {
    normalized.category = normalized.category.toString().trim().toLowerCase();
    if (!allowedCategories.includes(normalized.category)) {
      throw new AppError('Invalid category', 400);
    }
  }

  if (normalized.season) {
    normalized.season = normalized.season.toString().trim().toLowerCase();
    if (!allowedSeasons.includes(normalized.season)) {
      throw new AppError('Invalid season', 400);
    }
  }

  if (normalized.laundryStatus) {
    normalized.laundryStatus = normalized.laundryStatus.toString().trim().toLowerCase();
    if (!allowedLaundryStatuses.includes(normalized.laundryStatus)) {
      throw new AppError('Invalid laundry status', 400);
    }
  }

  normalized.secondaryColors = toStringArray(normalized.secondaryColors);
  normalized.occasions = toStringArray(normalized.occasions);
  normalized.weatherSuitability = toStringArray(normalized.weatherSuitability);

  return normalized;
};

export const parseJsonFromText = (text = '') => {
  const raw = typeof text === 'string' ? text : '';
  let cleaned = raw.replace(/```(?:json)?/gi, '').trim();
  const fencedMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fencedMatch?.[1]) {
    cleaned = fencedMatch[1].trim();
  }

  try {
    return JSON.parse(cleaned);
  } catch (error) {
    const match = cleaned.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        return JSON.parse(match[0]);
      } catch (nestedError) {
        throw new AppError(`Failed to parse AI response JSON: ${nestedError.message}`, 502, {
          rawText: cleaned,
          parseError: nestedError.message,
        });
      }
    }

    throw new AppError(`Failed to parse AI response JSON: ${error.message}`, 502, {
      rawText: cleaned,
      parseError: error.message,
    });
  }
};

const normalizeConfidence = (confidence = {}) => {
  const fields = ['category', 'color', 'pattern', 'material', 'style', 'season'];
  const normalized = {};
  for (const field of fields) {
    const value = Number(confidence?.[field]);
    normalized[field] = Number.isFinite(value) ? Math.min(100, Math.max(0, Math.round(value))) : null;
  }
  return normalized;
};

const nonEmptyString = (value) => (typeof value === 'string' && value.trim() ? value.trim() : null);

/**
 * Normalizes raw Gemini JSON into the app's controlled vocabulary. Anything
 * the model returns that isn't a recognized value becomes null (or an empty
 * array for list fields) rather than being guessed at — the UI treats null
 * as "AI could not determine this" and keeps the field editable.
 */
export const normalizeAnalysis = (analysis = {}) => ({
  name: nonEmptyString(analysis.name) || '',
  category: normalizeEnumValue(analysis.category, allowedCategories, CATEGORY_ALIASES),
  subCategory: nonEmptyString(analysis.subcategory ?? analysis.subCategory) || '',
  color: nonEmptyString(analysis.color) || null,
  // Colors are free-form (no fixed enum) — just clean and dedupe.
  secondaryColors: [...new Set(toStringArray(analysis.secondaryColors).map((c) => c.trim().toLowerCase()))],
  pattern: normalizeEnumValue(analysis.pattern, PATTERN_OPTIONS, PATTERN_ALIASES),
  material: normalizeEnumValue(analysis.material, MATERIAL_OPTIONS),
  style: normalizeEnumValue(analysis.style, STYLE_OPTIONS),
  season: normalizeEnumValue(analysis.season, allowedSeasons, SEASON_ALIASES),
  occasions: normalizeEnumList(toStringArray(analysis.occasions), OCCASION_OPTIONS, OCCASION_ALIASES),
  weatherSuitability: normalizeEnumList(toStringArray(analysis.weatherSuitability), WEATHER_OPTIONS),
  fit: normalizeEnumValue(analysis.fit, FIT_OPTIONS, FIT_ALIASES),
  // Never fabricated — pass through only if Gemini actually returned text.
  brand: nonEmptyString(analysis.brand),
  size: nonEmptyString(analysis.size),
  confidence: normalizeConfidence(analysis.confidence),
});

export const buildGeminiRequestBody = (prompt, buffer = null) => {
  const part = { text: prompt };
  const parts = [part];

  if (buffer) {
    parts.push({
      inlineData: {
        mimeType: 'image/jpeg',
        data: buffer.toString('base64'),
      },
    });
  }

  return {
    contents: [
      {
        parts,
      },
    ],
  };
};

export const validateGeminiModel = (model) => {
  if (typeof model !== 'string' || model.trim().length === 0) {
    throw new AppError('Gemini model is not configured', 500, { model });
  }
  if (!/^gemini-[A-Za-z0-9._-]+$/.test(model)) {
    throw new AppError(`Invalid Gemini model configured: ${model}`, 500, { model });
  }
};

export const validateAnalysisConfig = (env = process.env) => {
  const requiredKeys = [
    'GEMINI_API_KEY',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_API_KEY',
    'CLOUDINARY_API_SECRET',
    'JWT_SECRET',
  ];

  const missing = requiredKeys.filter((key) => !String(env[key] ?? '').trim());

  return {
    isValid: missing.length === 0,
    missing,
  };
};

const extractGeminiText = (responseData) => {
  const candidates = Array.isArray(responseData?.candidates) ? responseData.candidates : [];
  for (const candidate of candidates) {
    const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
    for (const part of parts) {
      if (typeof part?.text === 'string' && part.text.trim()) {
        return part.text;
      }
    }

    const combinedText = parts.map((part) => part?.text ?? '').join('').trim();
    if (combinedText) {
      return combinedText;
    }
  }

  return null;
};

const CLOTHING_ANALYSIS_PROMPT = `You are ClosetAI's professional clothing analysis engine.

Analyze ONLY the clothing item visible in the supplied image.

Return ONLY valid JSON. Do not include markdown. Do not include explanations.

Do not guess information that cannot be visually determined. For uncertain values use null.

Never invent: brand, size, price, purchase date, wear count, laundry status.

Detect: clothing category, subcategory, primary color, secondary colors, pattern, likely material, style, likely season, suitable occasions, weather suitability, fit only when visually reasonable, and a short clothing name (e.g. "Black Party Dress").

category must be one of: top, bottom, dress, outerwear, footwear, accessory, activewear, innerwear, other.
style must be one of: casual, formal, party, sporty, streetwear, traditional, business, minimal, elegant, ethnic.
pattern must be one of: solid, striped, checked, floral, printed, polka-dot, geometric, abstract, embroidered, other.
material must be one of: cotton, denim, linen, silk, wool, polyester, leather, rayon, chiffon, velvet, other, unknown.
season must be one of: spring, summer, autumn, winter, all-season.
occasions items must be from: casual, office, party, wedding, travel, workout, date, festival, formal, daily-wear.
weatherSuitability items must be from: hot, warm, mild, cool, cold, rainy.
fit must be one of: slim, regular, relaxed, oversized, or null.

Return confidence scores from 0 to 100 for AI-detected attributes.

Respond with exactly this JSON shape and nothing else:
{
  "name": string,
  "category": string,
  "subcategory": string|null,
  "color": string,
  "secondaryColors": string[],
  "pattern": string|null,
  "material": string|null,
  "style": string|null,
  "season": string|null,
  "occasions": string[],
  "weatherSuitability": string[],
  "fit": string|null,
  "brand": string|null,
  "size": string|null,
  "confidence": {
    "category": number,
    "color": number,
    "pattern": number,
    "material": number,
    "style": number,
    "season": number
  }
}`;

export const analyzeClothingImage = async (buffer) => {
  const config = validateAnalysisConfig(process.env);
  const apiKey = process.env.GEMINI_API_KEY;
  // 'gemini-2.0-flash' was retired by Google (confirmed via a live 404 during
  // testing). Use the "-latest" alias so this doesn't go stale again as
  // Google rolls new stable versions — override with GEMINI_MODEL if needed.
  const model = process.env.GEMINI_MODEL || 'gemini-flash-latest';

  if (!config.isValid) {
    throw new AppError('Missing required configuration for AI analysis', 500, { missing: config.missing });
  }

  if (!apiKey) {
    throw new AppError('Gemini API key is not configured. Set GEMINI_API_KEY in .env', 500);
  }

  validateGeminiModel(model);

  const requestBody = buildGeminiRequestBody(CLOTHING_ANALYSIS_PROMPT, buffer);
  const requestUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  debugLog('[AI ANALYZE] Requesting Gemini analysis', { model, bufferSize: buffer?.length ?? 0 });

  const response = await fetch(requestUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  const rawResponseText = await response.text();
  let data;

  try {
    data = JSON.parse(rawResponseText);
  } catch (parseError) {
    console.error('[AI ANALYZE] Gemini response was not valid JSON', { status: response.status, parseError: parseError.message });
    throw new AppError(`Gemini response was not valid JSON: ${parseError.message}`, 502, { rawResponseText });
  }

  if (!response.ok) {
    const errorMessage = data?.error?.message || data?.message || `Gemini request failed with status ${response.status}`;
    console.error('[AI ANALYZE] Gemini request failed', { status: response.status, errorMessage });
    throw new AppError(errorMessage, 502, { status: response.status, model });
  }

  const text = extractGeminiText(data);
  if (!text || typeof text !== 'string') {
    throw new AppError('Gemini response missing text content', 502, { rawResponseData: data });
  }

  const parsedAnalysis = parseJsonFromText(text);
  const normalizedAnalysis = normalizeAnalysis(parsedAnalysis);

  debugLog('[AI ANALYZE] Normalized analysis', normalizedAnalysis);

  return normalizedAnalysis;
};

export const buildClothingPayload = async ({ payload, imageUrl = '', publicId = '', userId, aiAnalysis = {} }) => {
  const normalized = normalizePayload(payload);

  const material = normalized.material || normalized.fabric || aiAnalysis.material || '';
  const secondaryColors = normalized.secondaryColors.length
    ? normalized.secondaryColors
    : aiAnalysis.secondaryColors || [];
  const occasions = normalized.occasions.length ? normalized.occasions : aiAnalysis.occasions || [];
  const cloudinaryPublicId = normalized.cloudinaryPublicId || publicId || '';

  const result = {
    userId,
    imageUrl,
    publicId,
    cloudinaryPublicId,
    name: normalized.name || aiAnalysis.name || '',
    category: normalized.category || aiAnalysis.category || 'other',
    subCategory: normalized.subCategory || aiAnalysis.subCategory || '',
    color: normalized.color || aiAnalysis.color || '',
    secondaryColor: normalized.secondaryColor || secondaryColors[0] || '',
    secondaryColors,
    pattern: normalized.pattern || aiAnalysis.pattern || 'solid',
    fabric: material || normalized.fabric || 'unknown',
    material: material || 'unknown',
    style: normalized.style || aiAnalysis.style || '',
    fit: normalized.fit || aiAnalysis.fit || '',
    brand: normalized.brand || '',
    size: normalized.size || '',
    season: normalized.season || aiAnalysis.season || 'all-season',
    occasion: normalized.occasion || occasions[0] || 'casual',
    occasions,
    weatherSuitability: normalized.weatherSuitability,
    purchaseDate: normalized.purchaseDate || undefined,
    purchasePrice: normalized.purchasePrice || 0,
    favorite: normalized.favorite ?? false,
    laundryStatus: normalized.laundryStatus || 'clean',
    notes: normalized.notes || '',
    // wearCount/lastWorn deliberately omitted — backend-owned, see wear.service.js
  };

  if (normalized.aiAnalyzed) {
    result.aiAnalysis = {
      analyzed: true,
      analyzedAt: new Date(),
      confidence: normalizeConfidence(normalized.aiConfidence || {}),
    };
  }

  return result;
};
