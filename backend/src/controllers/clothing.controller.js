import { AppError } from '../utils/appError.js';
import { createClothingSchema, updateClothingSchema, wearClothingSchema } from '../validators/clothing.validator.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';
import { analyzeClothingImage, buildClothingPayload, validateAnalysisConfig } from '../services/clothing.service.js';
import { markClothingWorn } from '../services/wear.service.js';
import {
  createClothingItem,
  deleteClothingItem,
  findClothingById,
  findClothingItems,
  updateClothingItem,
} from '../repositories/clothing.repository.js';

export const createClothing = async (req, res, next) => {
  try {
    const body = req.body || {};
    const { error, value } = createClothingSchema.validate(body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    let imageUrl = value.imageUrl || '';
    let publicId = value.publicId || '';

    if (req.file) {
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      imageUrl = uploadResult.secure_url;
      publicId = uploadResult.public_id;
    }

    // AI analysis already happened (or was skipped) client-side via
    // POST /clothes/analyze before Save was pressed — never re-run it here.
    const payload = await buildClothingPayload({
      payload: value,
      imageUrl,
      publicId,
      userId: req.user._id,
    });

    const clothing = await createClothingItem(payload);
    res.status(201).json({ success: true, data: clothing });
  } catch (error) {
    next(error);
  }
};

export const listClothing = async (req, res, next) => {
  try {
    const {
      page,
      limit,
      search,
      category,
      color,
      brand,
      season,
      occasion,
      laundryStatus,
      favorite,
      sortBy,
      sortOrder,
    } = req.query;

    const result = await findClothingItems({
      userId: req.user._id,
      page,
      limit,
      search,
      category,
      color,
      brand,
      season,
      occasion,
      laundryStatus,
      favorite,
      sortBy,
      sortOrder,
    });

    res.status(200).json({ success: true, data: result.items, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const getClothing = async (req, res, next) => {
  try {
    const clothing = await findClothingById({ userId: req.user._id, id: req.params.id });
    if (!clothing) {
      throw new AppError('Clothing item not found', 404);
    }

    res.status(200).json({ success: true, data: clothing });
  } catch (error) {
    next(error);
  }
};

export const updateClothing = async (req, res, next) => {
  try {
    const body = req.body || {};
    const { error, value } = updateClothingSchema.validate(body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const clothing = await findClothingById({ userId: req.user._id, id: req.params.id });
    if (!clothing) {
      throw new AppError('Clothing item not found', 404);
    }

    let imageUrl = clothing.imageUrl;
    let publicId = clothing.publicId;

    if (req.file) {
      // Upload the replacement first, then remove the old asset only after
      // the new one is safely stored — never leave the item without an image.
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      imageUrl = uploadResult.secure_url;
      publicId = uploadResult.public_id;
      if (clothing.publicId) {
        await deleteFromCloudinary(clothing.publicId);
      }
    }

    const payload = await buildClothingPayload({
      payload: { ...value, imageUrl, publicId },
      imageUrl,
      publicId,
      userId: req.user._id,
    });

    const updatedClothing = await updateClothingItem({ userId: req.user._id, id: req.params.id, updateData: payload });
    res.status(200).json({ success: true, data: updatedClothing });
  } catch (error) {
    next(error);
  }
};

export const analyzeClothing = async (req, res, next) => {
  try {
    if (!req.file) {
      throw new AppError('Image file is required for analysis', 400);
    }

    const config = validateAnalysisConfig(process.env);
    if (!config.isValid) {
      throw new AppError('Missing required configuration for AI analysis', 500, { missing: config.missing });
    }

    // Analysis-only: the image is not uploaded to Cloudinary here. It's
    // uploaded exactly once, when the user presses Save (createClothing /
    // updateClothing), so a re-analyzed or discarded image never leaves an
    // orphaned asset behind.
    const aiAnalysis = await analyzeClothingImage(req.file.buffer);
    res.status(200).json({ success: true, data: aiAnalysis });
  } catch (error) {
    next(error);
  }
};

export const markClothingAsWorn = async (req, res, next) => {
  try {
    const { error, value } = wearClothingSchema.validate(req.body || {});
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const { clothing, wearHistory } = await markClothingWorn({
      userId: req.user._id,
      clothingId: req.params.id,
      occasion: value.occasion,
      weather: value.weather,
      rating: value.rating,
      notes: value.notes,
    });

    res.status(200).json({ success: true, data: { clothing, wearHistory } });
  } catch (error) {
    next(error);
  }
};

export const deleteClothing = async (req, res, next) => {
  try {
    const clothing = await findClothingById({ userId: req.user._id, id: req.params.id });
    if (!clothing) {
      throw new AppError('Clothing item not found', 404);
    }

    if (clothing.publicId) {
      await deleteFromCloudinary(clothing.publicId);
    }

    await deleteClothingItem({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, message: 'Clothing item deleted successfully' });
  } catch (error) {
    next(error);
  }
};
