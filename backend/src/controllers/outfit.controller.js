import { AppError } from '../utils/appError.js';
import { generateOutfitRecommendation } from '../services/outfit.service.js';
import { createOutfitSchema, updateOutfitSchema, generateOutfitSchema } from '../validators/outfit.validator.js';
import {
  createOutfitRecord,
  deleteOutfitRecord,
  findOutfitById,
  findOutfitsForUser,
  updateOutfitRecord,
} from '../repositories/outfit.repository.js';
import Clothing from '../models/Clothing.js';
import { markManyClothingWorn } from '../services/wear.service.js';

const normalizeLaundryStatus = (value) => (value ?? '').toString().trim().toLowerCase();
const UNAVAILABLE_LAUNDRY_STATUSES = new Set(['dirty', 'washing', 'repair', 'in-use', 'drying', 'ironing']);

export const createOutfit = async (req, res, next) => {
  try {
    const payload = { ...(req.body || {}) };
    for (const field of ['outerwear', 'accessories', 'bag', 'watch']) {
      if (payload[field] === null || payload[field] === undefined) payload[field] = '';
    }

    const { error, value } = createOutfitSchema.validate(payload);
    if (error) throw new AppError(error.details[0].message, 400);

    const savePayload = {
      ...value,
      userId: req.user?._id || req.user?.userId,
      recommendedItems: Array.isArray(value.recommendedItems) && value.recommendedItems.length > 0
        ? value.recommendedItems
        : [value.top, value.bottom, value.footwear].filter(Boolean).map((name) => ({ _id: '', name, category: 'Item' })),
    };

    console.log('[OUTFIT] Save payload', { savePayload });

    const outfit = await createOutfitRecord({ payload: savePayload });
    res.status(201).json({ success: true, data: outfit });
  } catch (error) {
    next(error);
  }
};

export const listOutfits = async (req, res, next) => {
  try {
    const { favorite, search } = req.query;
    const outfits = await findOutfitsForUser({
      userId: req.user._id,
      favorite: favorite === undefined ? undefined : favorite === 'true',
      search,
    });

    res.status(200).json({ success: true, data: outfits });
  } catch (error) {
    next(error);
  }
};

export const getOutfit = async (req, res, next) => {
  try {
    const outfit = await findOutfitById({ userId: req.user._id, id: req.params.id });
    if (!outfit) throw new AppError('Outfit not found', 404);
    res.status(200).json({ success: true, data: outfit });
  } catch (error) {
    next(error);
  }
};

export const updateOutfit = async (req, res, next) => {
  try {
    const { error, value } = updateOutfitSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const outfit = await updateOutfitRecord({ userId: req.user._id, id: req.params.id, updateData: value });
    if (!outfit) throw new AppError('Outfit not found', 404);

    res.status(200).json({ success: true, data: outfit });
  } catch (error) {
    next(error);
  }
};

export const deleteOutfit = async (req, res, next) => {
  try {
    const outfit = await deleteOutfitRecord({ userId: req.user._id, id: req.params.id });
    if (!outfit) throw new AppError('Outfit not found', 404);
    res.status(200).json({ success: true, message: 'Outfit deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const generateOutfit = async (req, res, next) => {
  try {
    const { error, value } = generateOutfitSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const userId = req.user?._id || req.user?.userId;
    console.log('[OUTFIT] Authenticated user', { userId });

    const wardrobe = await Clothing.find({ userId }).lean();

    const dirtyItems = wardrobe.filter((item) => UNAVAILABLE_LAUNDRY_STATUSES.has(normalizeLaundryStatus(item?.laundryStatus)));
    const cleanItems = wardrobe.filter((item) => !dirtyItems.includes(item));

    console.log('[OUTFIT] Total clothes', { count: wardrobe.length });
    console.log('[OUTFIT] Clean clothes', { count: cleanItems.length });
    console.log('[OUTFIT] Dirty clothes', { count: dirtyItems.length });
    console.log('[OUTFIT] Grouped categories', {
      counts: Object.entries(
        wardrobe.reduce((acc, item) => {
          const category = (item?.category || 'other').toString();
          acc[category] = (acc[category] || 0) + 1;
          return acc;
        }, {}),
      ).map(([key, count]) => ({ category: key, count })),
    });
    console.log('[OUTFIT] Wardrobe JSON', { wardrobe });

    const recommendation = await generateOutfitRecommendation({ wardrobe: cleanItems.length > 0 ? cleanItems : wardrobe, request: value });

    if (!recommendation.success) {
      res.status(200).json({ success: false, reason: recommendation.reason });
      return;
    }

    res.status(200).json({ success: true, data: recommendation });
  } catch (error) {
    next(error);
  }
};

export const wearOutfit = async (req, res, next) => {
  try {
    const { outfitId } = req.body || {};
    if (!outfitId) {
      throw new AppError('outfitId is required', 400);
    }

    const outfit = await findOutfitById({ userId: req.user._id, id: outfitId });
    if (!outfit) {
      throw new AppError('Outfit not found', 404);
    }

    const itemIds = (outfit.recommendedItems || [])
      .map((item) => item?._id)
      .filter(Boolean);

    const now = new Date();
    const results = await markManyClothingWorn({
      userId: req.user._id,
      clothingIds: itemIds,
      outfitId,
      occasion: outfit.occasion || '',
      weather: outfit.weather || '',
      wornAt: now,
    });

    console.log('[OUTFIT] Wear API payload', { outfitId, itemIds, now: now.toISOString() });
    console.log('[OUTFIT] Wear transaction complete', { outfitId, updatedCount: results.length });

    await updateOutfitRecord({ userId: req.user._id, id: outfitId, updateData: { status: 'worn' } });

    res.status(200).json({
      success: true,
      message: 'Outfit marked as worn.',
      data: {
        outfitId,
        updatedCount: results.length,
        lastWorn: now.toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const favoriteOutfit = async (req, res, next) => {
  try {
    const { id, favorite } = req.body || {};
    if (!id) throw new AppError('Outfit id is required', 400);

    const outfit = await updateOutfitRecord({
      userId: req.user._id,
      id,
      updateData: { favorite: Boolean(favorite) },
    });

    if (!outfit) throw new AppError('Outfit not found', 404);

    res.status(200).json({ success: true, data: outfit });
  } catch (error) {
    next(error);
  }
};

export const aiGenerateOutfits = generateOutfit;
