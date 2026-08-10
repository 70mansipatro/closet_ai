import Joi from 'joi';

const dateOrderValidation = (value, helpers) => {
  if (value.startDate && value.endDate) {
    const start = new Date(value.startDate);
    const end = new Date(value.endDate);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      return helpers.error('any.invalid');
    }
    if (end < start) {
      return helpers.message('endDate must be the same or after startDate');
    }
  }
  return value;
};

export const createTripSchema = Joi.object({
  tripName: Joi.string().max(100).required(),
  destination: Joi.string().max(100).required(),
  country: Joi.string().max(100).required(),
  city: Joi.string().max(100).required(),
  startDate: Joi.date().required(),
  endDate: Joi.date().required(),
  activities: Joi.array().items(Joi.string().max(80)).default([]),
  notes: Joi.string().max(2000).optional(),
  weatherSummary: Joi.string().max(500).optional(),
  averageTemperature: Joi.number().optional(),
}).custom(dateOrderValidation, 'date order validation');

export const updateTripSchema = Joi.object({
  tripName: Joi.string().max(100).optional(),
  destination: Joi.string().max(100).optional(),
  country: Joi.string().max(100).optional(),
  city: Joi.string().max(100).optional(),
  startDate: Joi.date().optional(),
  endDate: Joi.date().optional(),
  activities: Joi.array().items(Joi.string().max(80)).optional(),
  notes: Joi.string().max(2000).optional(),
  weatherSummary: Joi.string().max(500).optional(),
  averageTemperature: Joi.number().optional(),
}).min(1).custom(dateOrderValidation, 'date order validation');
