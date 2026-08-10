import Joi from 'joi';

export const createHistorySchema = Joi.object({
  clothingId: Joi.string().required(),
  outfitId: Joi.string().allow(null, '').optional(),
  date: Joi.date().required(),
  occasion: Joi.string().max(80).optional(),
  weather: Joi.string().max(40).optional(),
  rating: Joi.number().min(0).max(5).optional(),
  favorite: Joi.boolean().optional(),
  notes: Joi.string().max(1000).optional(),
});
