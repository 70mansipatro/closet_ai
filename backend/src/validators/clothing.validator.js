import Joi from 'joi';
import {
  CATEGORY_OPTIONS,
  SEASON_OPTIONS,
  LAUNDRY_STATUS_OPTIONS,
  STYLE_OPTIONS,
  FIT_OPTIONS,
  OCCASION_OPTIONS,
  WEATHER_OPTIONS,
} from '../constants/clothingOptions.js';

const colorPattern = /^[\p{L}\p{N}\s#-]+$/u;

// Multipart requests always arrive as strings, while JSON-body requests may
// send real arrays. Accept a real array, a JSON-encoded array string, or a
// comma-separated string, and normalize to an array either way.
const arrayField = (itemSchema) =>
  Joi.custom((value, helpers) => {
    if (Array.isArray(value)) return value;
    if (typeof value !== 'string' || !value.trim()) return [];
    const trimmed = value.trim();
    if (trimmed.startsWith('[')) {
      try {
        const parsed = JSON.parse(trimmed);
        if (Array.isArray(parsed)) return parsed;
      } catch {
        return helpers.error('any.invalid');
      }
    }
    return trimmed.split(',').map((part) => part.trim()).filter(Boolean);
  }).custom((value, helpers) => {
    for (const item of value) {
      const { error } = itemSchema.validate(item);
      if (error) return helpers.error('any.invalid');
    }
    return value;
  });

const clothingSchemaFields = {
  name: Joi.string().max(120).optional().allow(''),
  category: Joi.string().valid(...CATEGORY_OPTIONS).required(),
  subCategory: Joi.string().max(80).optional().allow(''),
  color: Joi.string().max(50).pattern(colorPattern).optional().allow(''),
  secondaryColor: Joi.string().max(50).pattern(colorPattern).optional().allow(''),
  secondaryColors: arrayField(Joi.string().max(50)).optional(),
  pattern: Joi.string().max(50).optional().allow(''),
  fabric: Joi.string().max(50).optional().allow(''),
  material: Joi.string().max(50).optional().allow(''),
  style: Joi.string().valid(...STYLE_OPTIONS).optional().allow(''),
  fit: Joi.string().valid(...FIT_OPTIONS).optional().allow(''),
  brand: Joi.string().max(80).optional().allow(''),
  size: Joi.string().max(40).optional().allow(''),
  season: Joi.string().valid(...SEASON_OPTIONS).optional().allow(''),
  occasion: Joi.string().max(80).optional().allow(''),
  occasions: arrayField(Joi.string().valid(...OCCASION_OPTIONS)).optional(),
  weatherSuitability: arrayField(Joi.string().valid(...WEATHER_OPTIONS)).optional(),
  purchaseDate: Joi.date().optional(),
  purchasePrice: Joi.number().min(0).optional(),
  favorite: Joi.boolean().optional(),
  laundryStatus: Joi.string().valid(...LAUNDRY_STATUS_OPTIONS).optional().allow(''),
  notes: Joi.string().max(1000).optional().allow(''),
  imageUrl: Joi.string().uri().optional().allow(''),
  publicId: Joi.string().optional().allow(''),
  // Set by the client after a successful /analyze pass; never trusted blindly
  // (see buildClothingPayload, which only stores this alongside real values).
  aiAnalyzed: Joi.boolean().optional(),
  // Multipart requests send this as a JSON-encoded string; JSON-body
  // requests may send a real object. Accept either.
  aiConfidence: Joi.custom((value, helpers) => {
    if (value === undefined || value === null || value === '') return undefined;
    if (typeof value === 'string') {
      try {
        return JSON.parse(value);
      } catch {
        return helpers.error('any.invalid');
      }
    }
    return value;
  })
    .custom((value) => {
      const { error, value: validated } = Joi.object({
        category: Joi.number().min(0).max(100),
        color: Joi.number().min(0).max(100),
        pattern: Joi.number().min(0).max(100),
        material: Joi.number().min(0).max(100),
        style: Joi.number().min(0).max(100),
        season: Joi.number().min(0).max(100),
      }).validate(value);
      if (error) return undefined;
      return validated;
    })
    .optional(),
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
