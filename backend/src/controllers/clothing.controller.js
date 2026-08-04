import { AppError } from '../utils/appError.js';
import { createClothingSchema, updateClothingSchema } from '../validators/clothing.validator.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';
import { analyzeClothingImage, buildClothingPayload, validateAnalysisConfig } from '../services/clothing.service.js';
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
    let aiAnalysis = {};

    if (req.file) {
      aiAnalysis = await analyzeClothingImage(req.file.buffer);
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      imageUrl = uploadResult.secure_url;
      publicId = uploadResult.public_id;
    }

    const payload = await buildClothingPayload({
      payload: value,
      imageUrl,
      publicId,
      userId: req.user._id,
      aiAnalysis,
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

    let aiAnalysis = {};
    let imageUrl = clothing.imageUrl;
    let publicId = clothing.publicId;

    if (req.file) {
      aiAnalysis = await analyzeClothingImage(req.file.buffer);
      if (clothing.publicId) {
        await deleteFromCloudinary(clothing.publicId);
      }
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      imageUrl = uploadResult.secure_url;
      publicId = uploadResult.public_id;
    }

    const payload = await buildClothingPayload({
      payload: { ...value, imageUrl, publicId },
      imageUrl,
      publicId,
      userId: req.user._id,
      aiAnalysis,
    });

    const updatedClothing = await updateClothingItem({ userId: req.user._id, id: req.params.id, updateData: payload });
    res.status(200).json({ success: true, data: updatedClothing });
  } catch (error) {
    next(error);
  }
};

export const analyzeClothing = async (req, res, next) => {
  try {
    console.log('[BACKEND] Clothing analyze request received', {
      path: req.originalUrl,
      method: req.method,
      userId: req.user?._id,
      hasFile: !!req.file,
      file: req.file
        ? {
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
          }
        : null,
    });

    if (!req.file) {
      throw new AppError('Image file is required for analysis', 400);
    }

    const config = validateAnalysisConfig(process.env);
    if (!config.isValid) {
      throw new AppError('Missing required configuration for AI analysis', 500, { missing: config.missing });
    }

    const aiAnalysis = await analyzeClothingImage(req.file.buffer);
    const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/analysis');
    res.status(200).json({
      success: true,
      data: {
        ...aiAnalysis,
        imageUrl: uploadResult?.secure_url || '',
        publicId: uploadResult?.public_id || '',
      },
    });
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
