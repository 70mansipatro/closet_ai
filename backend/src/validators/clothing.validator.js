import Joi from 'joi';

export const createClothingSchema = Joi.object({
  name: Joi.string().max(100).required(),
  category: Joi.string().valid('top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other').required(),
  color: Joi.string().max(50).optional(),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  occasion: Joi.string().max(100).optional(),
  tags: Joi.array().items(Joi.string()).optional(),
  isFavorite: Joi.boolean().optional(),
  notes: Joi.string().max(1000).optional(),
});

export const updateClothingSchema = Joi.object({
  name: Joi.string().max(100).optional(),
  category: Joi.string().valid('top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other').optional(),
  color: Joi.string().max(50).optional(),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  occasion: Joi.string().max(100).optional(),
  tags: Joi.array().items(Joi.string()).optional(),
  isFavorite: Joi.boolean().optional(),
  notes: Joi.string().max(1000).optional(),
}).min(1);
