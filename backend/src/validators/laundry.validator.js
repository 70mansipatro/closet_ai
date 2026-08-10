import Joi from 'joi';

const allowedLaundryStatuses = ['clean', 'dirty', 'washing', 'drying', 'ironing', 'ready', 'in-use', 'repair'];

export const laundryStatusSchema = Joi.object({
  newStatus: Joi.string().valid(...allowedLaundryStatuses).required(),
  method: Joi.string().trim().max(100).optional().allow(''),
  notes: Joi.string().max(1000).optional().allow(''),
});

export const laundryBulkStatusSchema = Joi.object({
  clothingIds: Joi.array().items(Joi.string().required()).min(1).required(),
  newStatus: Joi.string().valid(...allowedLaundryStatuses).required(),
  method: Joi.string().trim().max(100).optional().allow(''),
  notes: Joi.string().max(1000).optional().allow(''),
});

export const laundryHistoryQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  clothingId: Joi.string().optional().allow(''),
  newStatus: Joi.string().valid(...allowedLaundryStatuses).optional(),
  startDate: Joi.date().optional(),
  endDate: Joi.date().optional(),
  search: Joi.string().trim().optional().allow(''),
});

export const laundryListQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  search: Joi.string().trim().optional().allow(''),
  category: Joi.string().trim().optional().allow(''),
  color: Joi.string().trim().optional().allow(''),
  brand: Joi.string().trim().optional().allow(''),
  season: Joi.string().trim().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  occasion: Joi.string().trim().optional().allow(''),
  laundryStatus: Joi.string().valid(...allowedLaundryStatuses).optional(),
  sortBy: Joi.string().trim().optional().allow(''),
  sortOrder: Joi.string().valid('asc', 'desc').optional(),
});
