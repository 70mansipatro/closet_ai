import Joi from 'joi';

const dateQuerySchema = Joi.object({
  from: Joi.string().isoDate().optional().allow(''),
  to: Joi.string().isoDate().optional().allow(''),
  interval: Joi.string().valid('weekly', 'monthly', 'yearly').optional(),
});

export const analyticsDateRangeSchema = Joi.object({
  from: Joi.string().optional().allow('').custom((value, helpers) => {
    if (!value) return value;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return helpers.error('any.invalid');
    }
    return value;
  }, 'ISO date validation'),
  to: Joi.string().optional().allow('').custom((value, helpers) => {
    if (!value) return value;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return helpers.error('any.invalid');
    }
    return value;
  }, 'ISO date validation'),
  interval: Joi.string().valid('weekly', 'monthly', 'yearly').optional(),
});

export const analyticsQuerySchema = dateQuerySchema.custom((value, helpers) => {
  if ((value.from && !value.to) || (!value.from && value.to)) {
    return helpers.error('any.custom', { message: 'Both from and to are required for a date range filter' });
  }
  if (value.from && value.to) {
    const fromDate = new Date(value.from);
    const toDate = new Date(value.to);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
      return helpers.error('any.invalid');
    }
    if (fromDate.getTime() > toDate.getTime()) {
      return helpers.error('any.custom', { message: 'Invalid date range: from must be before to' });
    }
  }
  return value;
}, 'Date range validation');

export const analyticsInsightsSchema = Joi.object({
  interval: Joi.string().valid('weekly', 'monthly', 'yearly').optional(),
});
