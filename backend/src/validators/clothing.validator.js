import Joi from 'joi';

const colorPattern = /^[\p{L}\p{N}\s#-]+$/u;

const clothingSchemaFields = {
  name: Joi.string().max(120).optional().allow(''),
  category: Joi.string().valid('top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other').required(),
  subCategory: Joi.string().max(80).optional().allow(''),
  color: Joi.string().max(50).pattern(colorPattern).optional().allow(''),
  secondaryColor: Joi.string().max(50).pattern(colorPattern).optional().allow(''),
  pattern: Joi.string().max(50).optional().allow(''),
  fabric: Joi.string().max(50).optional().allow(''),
  brand: Joi.string().max(80).optional().allow(''),
  size: Joi.string().max(40).optional().allow(''),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional().allow(''),
  occasion: Joi.string().max(80).optional().allow(''),
  purchaseDate: Joi.date().optional(),
  purchasePrice: Joi.number().min(0).optional(),
  favorite: Joi.boolean().optional(),
  laundryStatus: Joi.string().valid('clean', 'dirty', 'washing', 'drying', 'ironing', 'ready', 'in-use', 'repair').optional().allow(''),
  notes: Joi.string().max(1000).optional().allow(''),
  imageUrl: Joi.string().uri().optional().allow(''),
  publicId: Joi.string().optional().allow(''),
};

// wearCount and lastWorn are intentionally NOT part of this schema — they are
// backend-owned and only ever change via the wear-tracking transaction (see
// services/wear.service.js). buildClothingPayload() strips them defensively
// even though `.unknown(true)` below would otherwise let them through.

export const createClothingSchema = Joi.object(clothingSchemaFields).unknown(true);

export const updateClothingSchema = Joi.object(
  Object.fromEntries(
    Object.entries(clothingSchemaFields).map(([key, schema]) => [key, schema.optional()]),
  ),
).unknown(true).min(1);

export const wearClothingSchema = Joi.object({
  occasion: Joi.string().valid('Casual', 'Work', 'Party', 'Date', 'Travel', 'Workout', 'Dinner', 'Other').default('Casual'),
  rating: Joi.number().integer().min(0).max(5).optional(),
  notes: Joi.string().max(1000).optional().allow(''),
  weather: Joi.string().max(40).optional().allow(''),
});
