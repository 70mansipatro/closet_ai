import Joi from 'joi';

export const userListQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  search: Joi.string().allow('').optional(),
  status: Joi.string().valid('active', 'suspended', 'inactive').optional(),
  subscription: Joi.string().valid('free', 'premium').optional(),
  role: Joi.string().valid('user', 'admin', 'super_admin').optional(),
});

export const userStatusUpdateSchema = Joi.object({
  status: Joi.string().valid('active', 'suspended', 'inactive').required(),
});

export const userRoleUpdateSchema = Joi.object({
  role: Joi.string().valid('user', 'admin', 'super_admin').required(),
});

export const subscriptionListQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  status: Joi.string().valid('pending', 'active', 'cancelled', 'expired', 'past_due', 'failed').optional(),
  plan: Joi.string().optional(),
  search: Joi.string().allow('').optional(),
});

export const planCreateSchema = Joi.object({
  name: Joi.string().min(2).max(80).required(),
  planCode: Joi.string().min(2).max(60).required(),
  description: Joi.string().allow('').optional(),
  price: Joi.number().min(0).required(),
  currency: Joi.string().length(3).optional(),
  billingPeriod: Joi.string().valid('none', 'monthly', 'yearly').required(),
  features: Joi.array().items(Joi.string()).optional(),
  limits: Joi.object().optional(),
  isActive: Joi.boolean().optional(),
  sortOrder: Joi.number().optional(),
});

export const planUpdateSchema = Joi.object({
  name: Joi.string().min(2).max(80).optional(),
  description: Joi.string().allow('').optional(),
  price: Joi.number().min(0).optional(),
  currency: Joi.string().length(3).optional(),
  billingPeriod: Joi.string().valid('none', 'monthly', 'yearly').optional(),
  features: Joi.array().items(Joi.string()).optional(),
  limits: Joi.object().optional(),
  sortOrder: Joi.number().optional(),
});

export const planStatusUpdateSchema = Joi.object({
  isActive: Joi.boolean().required(),
});

export const paymentListQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  status: Joi.string().valid('created', 'pending', 'success', 'failed', 'refunded').optional(),
  provider: Joi.string().optional(),
  search: Joi.string().allow('').optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
});

export const revenueQuerySchema = Joi.object({
  range: Joi.string().valid('today', '7d', '30d', '3m', '6m', '1y').optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
  groupBy: Joi.string().valid('day', 'month').optional(),
});

export const analyticsQuerySchema = Joi.object({
  range: Joi.string().valid('today', '7d', '30d', '3m', '6m', '1y').optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
  groupBy: Joi.string().valid('day', 'month').optional(),
});

export const reportExportSchema = Joi.object({
  type: Joi.string()
    .valid('users', 'subscriptions', 'payments', 'revenue', 'ai_usage', 'wardrobe', 'outfits', 'laundry', 'trips')
    .required(),
  format: Joi.string().valid('csv').default('csv'),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
  status: Joi.string().optional(),
  plan: Joi.string().optional(),
  role: Joi.string().optional(),
});

export const auditLogQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  action: Joi.string().optional(),
  adminUserId: Joi.string().optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
});

export const settingsUpdateSchema = Joi.object({
  maintenanceMode: Joi.object({
    enabled: Joi.boolean().optional(),
    message: Joi.string().allow('').max(500).optional(),
  }).optional(),
  notifications: Joi.object({
    announcementBanner: Joi.string().allow('').max(500).optional(),
    templatesPlaceholder: Joi.object().optional(),
  }).optional(),
});
