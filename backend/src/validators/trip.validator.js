import Joi from 'joi';

export const createTripSchema = Joi.object({
  title: Joi.string().max(100).required(),
  destination: Joi.string().max(100).required(),
  startDate: Joi.date().required(),
  endDate: Joi.date().greater(Joi.ref('startDate')).required(),
  notes: Joi.string().max(2000).optional(),
  packingList: Joi.array().items(
    Joi.object({
      item: Joi.string().required(),
      packed: Joi.boolean().optional(),
      category: Joi.string().optional(),
    })
  ).optional(),
});

export const updateTripSchema = Joi.object({
  title: Joi.string().max(100).optional(),
  destination: Joi.string().max(100).optional(),
  startDate: Joi.date().optional(),
  endDate: Joi.date().greater(Joi.ref('startDate')).optional(),
  notes: Joi.string().max(2000).optional(),
  packingList: Joi.array().items(
    Joi.object({
      item: Joi.string().required(),
      packed: Joi.boolean().optional(),
      category: Joi.string().optional(),
    })
  ).optional(),
}).min(1);
