import Joi from 'joi';

export const scheduleSchema = Joi.object({
  date: Joi.date().required(),
  outfitId: Joi.string().allow(null, '').optional(),
  topId: Joi.string().allow(null, '').optional(),
  bottomId: Joi.string().allow(null, '').optional(),
  footwearId: Joi.string().allow(null, '').optional(),
  outerwearId: Joi.string().allow(null, '').optional(),
  accessories: Joi.array().items(Joi.string()).optional(),
  notes: Joi.string().max(1000).optional(),
  occasion: Joi.string().max(80).optional(),
  weather: Joi.string().max(40).optional(),
  temperature: Joi.number().min(-30).max(60).optional(),
  status: Joi.string().valid('Planned', 'Worn', 'Skipped').optional(),
});
