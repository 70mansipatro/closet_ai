import Joi from 'joi';

export const createOutfitSchema = Joi.object({
  name: Joi.string().max(100).required(),
  description: Joi.string().max(1000).optional(),
  items: Joi.array().items(Joi.string()).required(),
  occasion: Joi.string().max(100).optional(),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  isFavorite: Joi.boolean().optional(),
  aiGenerated: Joi.boolean().optional(),
});

export const updateOutfitSchema = Joi.object({
  name: Joi.string().max(100).optional(),
  description: Joi.string().max(1000).optional(),
  items: Joi.array().items(Joi.string()).optional(),
  occasion: Joi.string().max(100).optional(),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  isFavorite: Joi.boolean().optional(),
  aiGenerated: Joi.boolean().optional(),
}).min(1);
