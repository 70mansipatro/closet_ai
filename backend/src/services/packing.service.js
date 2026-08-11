import { AppError } from '../utils/appError.js';
import Clothing from '../models/Clothing.js';
import Trip from '../models/Trip.js';
import { findTripById } from '../repositories/trip.repository.js';
import {
  createPackingItems,
  deletePackingForTrip,
  findPackingForTrip,
  findPackingItemById,
  updatePackingItem as updatePackingItemRepo,
  deletePackingItem as deletePackingItemRepo,
} from '../repositories/packing.repository.js';
import { getWeather } from './weather.service.js';
import { buildGeminiRequestBody, validateGeminiModel } from './clothing.service.js';
import { cancelPackingReminder } from './reminder.service.js';

const checkPackingCompletionSafely = async ({ userId, tripId }) => {
  try {
    const items = await findPackingForTrip({ userId, tripId });
    const total = items.length;
    const packedCount = items.filter((item) => item.packed).length;
    if (total > 0 && packedCount >= total) {
      await cancelPackingReminder({ userId, tripId });
    }
  } catch (error) {
    console.error('[REMINDER HOOK] failed to check packing completion', { userId, tripId, error: error.message });
  }
};

const parseJson = (value) => {
  if (!value || typeof value !== 'string') return null;
  try {
    return JSON.parse(value.replace(/```json|```/g, '').trim());
  } catch {
    return null;
  }
};

const allowedCategories = new Set([
  'Clothes',
  'Shoes',
  'Accessories',
  'Electronics',
  'Documents',
  'Toiletries',
  'Medicines',
  'Other',
]);

const mapToPackingItem = ({ item, clothingId, quantity = 1, packed = false, required = true, category = 'Other', reason = '' }) => ({
  category: allowedCategories.has(category) ? category : 'Other',
  name: typeof item === 'string' ? item.trim() : '',
  clothingId: clothingId || undefined,
  quantity: Number.isFinite(quantity) ? Math.max(1, Number(quantity)) : 1,
  packed: Boolean(packed),
  required: Boolean(required),
  reason: typeof reason === 'string' ? reason.trim() : '',
});

const isClothingAvailable = (clothing) => {
  if (!clothing) return false;
  if (clothing.isDeleted || clothing.deleted || clothing.deletedAt) return false;
  const status = (clothing.laundryStatus || '').toString().trim().toLowerCase();
  return status === 'clean' || status === 'ready';
};

const makePackingPayloadFromGemini = async ({ trip, wardrobe, laundryItems, weather, request }) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new AppError('Gemini API key is not configured', 500);
  }

  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
  validateGeminiModel(model);

  const usableClothing = wardrobe.filter(isClothingAvailable);
  if (!usableClothing.length) {
    throw new AppError('No available clean wardrobe items found for packing recommendation', 422);
  }

  const prompt = [
    'Return JSON only with keys: summary, clothes, shoes, accessories, electronics, documents, toiletries, medicines, outfitSuggestions, tips.',
    'Each clothing item entry must include clothingId, quantity, and reason.',
    'Only include clothingId values from the provided wardrobe list. Do not invent clothing IDs.',
    'Do not recommend dirty, washing, drying, ironing, or otherwise unavailable clothing.',
    `Trip destination: ${trip.destination}, country: ${trip.country || 'unspecified'}, city: ${trip.city || 'unspecified'}.`,
    `Trip dates: ${trip.startDate.toISOString().slice(0, 10)} to ${trip.endDate.toISOString().slice(0, 10)}.`,
    `Trip duration: ${Math.ceil((trip.endDate - trip.startDate) / (1000 * 60 * 60 * 24)) + 1} days.`,
    `Trip activities: ${trip.activities.join(', ')}.`,
    `Weather summary: ${weather.weatherSummary || 'Unknown'}. Forecast entries: ${weather.forecast.length}.`,
    `Temperature range: ${weather.forecast.map((day) => day.temperature ?? 'N/A').join(', ')}.`,
    `Rain probabilities: ${weather.forecast.map((day) => day.rainProbability ?? 'N/A').join(', ')}.`,
    `Available wardrobe items (only include IDs): ${JSON.stringify(usableClothing.map((item) => ({
      _id: String(item._id),
      name: item.name,
      category: item.category,
      subCategory: item.subCategory,
      color: item.color,
      season: item.season,
      occasion: item.occasion,
      laundryStatus: item.laundryStatus,
      lastWorn: item.lastWorn ? item.lastWorn.toISOString() : null,
      wearCount: item.wearCount || 0,
    })))}.`,
    'Avoid recommending duplicate items. Prefer versatile items and those worn less recently. Include quantities only for items that should be packed multiple times.',
  ].join(' ');

  const body = buildGeminiRequestBody(prompt, null);
  const requestUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const response = await fetch(requestUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const raw = await response.text();
  if (!response.ok) {
    throw new AppError(`Gemini request failed with status ${response.status}`, 502, { raw });
  }

  const parsed = parseJson(raw);
  if (!parsed || typeof parsed !== 'object') {
    throw new AppError('Gemini returned invalid packing response', 502, { raw });
  }

  if (!Array.isArray(parsed.clothes) || !Array.isArray(parsed.shoes) || !Array.isArray(parsed.accessories)) {
    throw new AppError('Gemini packing response is missing required arrays', 502, { parsed });
  }

  const validateItem = (item) => {
    if (!item || typeof item !== 'object') return null;
    if (!item.clothingId || !item.reason) return null;
    const quantity = Number.isFinite(Number(item.quantity)) ? Number(item.quantity) : 1;
    return { clothingId: String(item.clothingId), quantity: Math.max(1, quantity), reason: String(item.reason) };
  };

  const toItems = (category, list) => {
    if (!Array.isArray(list)) return [];
    return list
      .map(validateItem)
      .filter(Boolean)
      .map((item) => {
        const clothing = usableClothing.find((wardrobeItem) => String(wardrobeItem._id) === item.clothingId);
        if (!clothing) return null;
        return {
          category,
          item: clothing.name,
          clothingId: clothing._id,
          quantity: item.quantity,
          packed: false,
          required: true,
          reason: item.reason,
        };
      })
      .filter(Boolean);
  };

  const clothes = toItems('Clothes', parsed.clothes);
  const shoes = toItems('Shoes', parsed.shoes);
  const accessories = toItems('Accessories', parsed.accessories);

  const manual = [];
  const addManualItems = (category, list) => {
    if (!Array.isArray(list)) return;
    list.forEach((item) => {
      if (!item || typeof item !== 'object') return;
      const name = (item.name || '').toString().trim();
      const quantity = Number.isFinite(Number(item.quantity)) ? Number(item.quantity) : 1;
      if (!name) return;
      manual.push({
        category,
        name,
        quantity: Math.max(1, quantity),
        packed: false,
        required: category !== 'Other',
        reason: (item.reason || '').toString().trim(),
      });
    });
  };

  addManualItems('Electronics', parsed.electronics);
  addManualItems('Documents', parsed.documents);
  addManualItems('Toiletries', parsed.toiletries);
  addManualItems('Medicines', parsed.medicines);
  addManualItems('Other', parsed.other);

  return {
    summary: parsed.summary || `Packing recommendation for ${trip.tripName}`,
    tips: Array.isArray(parsed.tips) ? parsed.tips.map((tip) => String(tip)) : [],
    items: [...clothes, ...shoes, ...accessories, ...manual],
  };
};

export const generatePackingList = async ({ userId, tripId }) => {
  const trip = await findTripById({ userId, id: tripId });
  if (!trip) {
    throw new AppError('Trip not found', 404);
  }

  const wardrobe = await Clothing.find({ userId, isDeleted: { $ne: true }, deleted: { $ne: true }, deletedAt: { $exists: false } }).lean();
  const cleanWardrobe = wardrobe.filter((item) => isClothingAvailable(item));
  const weather = await getWeather({ city: trip.city || trip.destination, country: trip.country, startDate: trip.startDate, endDate: trip.endDate });

  const packingResult = await makePackingPayloadFromGemini({ trip, wardrobe: cleanWardrobe, weather, request: { trip } });

  await deletePackingForTrip({ userId, tripId });
  if (packingResult.items.length > 0) {
    await createPackingItems({ payload: packingResult.items.map((item) => ({
      userId,
      tripId,
      ...item,
    })) });
  }

  return { summary: packingResult.summary, tips: packingResult.tips, items: packingResult.items };
};

export const listPackingList = async ({ userId, tripId }) => {
  await findTripById({ userId, id: tripId });
  return findPackingForTrip({ userId, tripId });
};

export const updatePackingItem = async ({ userId, tripId, itemId, updateData }) => {
  const item = await findPackingItemById({ userId, tripId, id: itemId });
  if (!item) throw new AppError('Packing item not found', 404);
  const payload = {};
  if (updateData.name !== undefined) payload.name = String(updateData.name).trim();
  if (updateData.category !== undefined && allowedCategories.has(updateData.category)) payload.category = updateData.category;
  if (updateData.quantity !== undefined) payload.quantity = Math.max(1, Number(updateData.quantity));
  if (updateData.packed !== undefined) payload.packed = Boolean(updateData.packed);
  if (updateData.required !== undefined) payload.required = Boolean(updateData.required);
  if (updateData.reason !== undefined) payload.reason = String(updateData.reason).trim();
  const updated = await updatePackingItemRepo({ userId, tripId, id: itemId, updateData: payload });
  if (payload.packed !== undefined) await checkPackingCompletionSafely({ userId, tripId });
  return updated;
};

export const deletePackingItem = async ({ userId, tripId, itemId }) => {
  const deleted = await deletePackingItemRepo({ userId, tripId, id: itemId });
  if (!deleted) throw new AppError('Packing item not found', 404);
  return deleted;
};

export const addManualPackingItem = async ({ userId, tripId, payload }) => {
  const trip = await findTripById({ userId, id: tripId });
  if (!trip) {
    throw new AppError('Trip not found', 404);
  }

  const item = mapToPackingItem(payload);
  if (!item.name) {
    throw new AppError('Item name is required', 400);
  }

  const record = await createPackingItems({ payload: [{ userId, tripId, ...item }] });
  return record[0];
};

export const togglePackingItem = async ({ userId, tripId, itemId }) => {
  const item = await findPackingItemById({ userId, tripId, id: itemId });
  if (!item) throw new AppError('Packing item not found', 404);
  const updated = await updatePackingItemRepo({ userId, tripId, id: itemId, updateData: { packed: !item.packed } });
  await checkPackingCompletionSafely({ userId, tripId });
  return updated;
};
