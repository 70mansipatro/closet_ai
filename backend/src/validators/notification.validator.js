import Joi from 'joi';
import { NOTIFICATION_TYPES } from '../models/Notification.js';
import { REMINDER_TYPES, REMINDER_FREQUENCIES, REMINDER_PRIORITIES } from '../models/Reminder.js';

export const ALLOWED_ACTION_ROUTES = [
  '',
  '/calendar',
  '/laundry',
  '/trips',
  '/packing',
  '/ai/stylist',
  '/subscription',
  '/wardrobe',
  '/history/wear',
  '/notifications',
];

export const notificationListQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  unreadOnly: Joi.boolean().truthy('true').falsy('false').optional(),
  type: Joi.string().valid(...NOTIFICATION_TYPES).optional(),
  startDate: Joi.date().optional(),
  endDate: Joi.date().optional(),
});

export const preferencesUpdateSchema = Joi.object({
  outfitReminders: Joi.boolean(),
  laundryReminders: Joi.boolean(),
  tripReminders: Joi.boolean(),
  packingReminders: Joi.boolean(),
  wearHistoryReminders: Joi.boolean(),
  wardrobeReminders: Joi.boolean(),
  aiStylistReminders: Joi.boolean(),
  subscriptionReminders: Joi.boolean(),
  premiumExpiryReminders: Joi.boolean(),
  smartReminders: Joi.boolean(),
  adminAnnouncements: Joi.boolean(),
  inAppEnabled: Joi.boolean(),
  localEnabled: Joi.boolean(),
  quietHoursEnabled: Joi.boolean(),
  quietHoursStart: Joi.string().pattern(/^\d{1,2}:\d{2}$/),
  quietHoursEnd: Joi.string().pattern(/^\d{1,2}:\d{2}$/),
  timezone: Joi.string().trim().max(64),
}).min(1);

export const smartSettingsUpdateSchema = Joi.object({
  enabled: Joi.boolean(),
  smartOutfit: Joi.boolean(),
  smartLaundry: Joi.boolean(),
  smartPacking: Joi.boolean(),
  smartTrip: Joi.boolean(),
  smartWardrobe: Joi.boolean(),
  smartWearHistory: Joi.boolean(),
  smartAIStylist: Joi.boolean(),
  maxDailyReminders: Joi.number().integer().min(0).max(20),
  minimumIntervalMinutes: Joi.number().integer().min(0).max(1440),
  quietHoursEnabled: Joi.boolean(),
}).min(1);

export const reminderCreateSchema = Joi.object({
  type: Joi.string().valid(...REMINDER_TYPES).default('CUSTOM'),
  title: Joi.string().trim().max(150).required(),
  description: Joi.string().trim().max(1000).allow(''),
  enabled: Joi.boolean().default(true),
  frequency: Joi.string().valid(...REMINDER_FREQUENCIES).default('once'),
  scheduledTime: Joi.string().pattern(/^\d{1,2}:\d{2}$/).allow(''),
  daysOfWeek: Joi.array().items(Joi.number().integer().min(0).max(6)),
  date: Joi.date().optional(),
  startDate: Joi.date().optional(),
  endDate: Joi.date().optional(),
  timezone: Joi.string().trim().max(64),
  priority: Joi.string().valid(...REMINDER_PRIORITIES).default('normal'),
  snoozeMinutes: Joi.number().integer().min(0),
  smartEnabled: Joi.boolean(),
});

export const reminderUpdateSchema = Joi.object({
  title: Joi.string().trim().max(150),
  description: Joi.string().trim().max(1000).allow(''),
  enabled: Joi.boolean(),
  frequency: Joi.string().valid(...REMINDER_FREQUENCIES),
  scheduledTime: Joi.string().pattern(/^\d{1,2}:\d{2}$/).allow(''),
  daysOfWeek: Joi.array().items(Joi.number().integer().min(0).max(6)),
  date: Joi.date(),
  startDate: Joi.date(),
  endDate: Joi.date(),
  timezone: Joi.string().trim().max(64),
  priority: Joi.string().valid(...REMINDER_PRIORITIES),
  snoozeMinutes: Joi.number().integer().min(0),
  smartEnabled: Joi.boolean(),
}).min(1);

export const reminderSnoozeSchema = Joi.object({
  preset: Joi.string().valid('15m', '30m', '1h', 'tomorrow'),
  minutes: Joi.number().integer().min(1).max(60 * 24 * 30),
}).xor('preset', 'minutes');

export const announcementCreateSchema = Joi.object({
  title: Joi.string().trim().max(150).required(),
  message: Joi.string().trim().max(1000).required(),
  priority: Joi.string().valid('low', 'normal', 'high', 'urgent').default('normal'),
  targetAudience: Joi.string().valid('all', 'free', 'premium', 'specificUsers').default('all'),
  targetUserIds: Joi.array().items(Joi.string()).when('targetAudience', {
    is: 'specificUsers',
    then: Joi.array().items(Joi.string()).min(1).required(),
    otherwise: Joi.array().items(Joi.string()).optional(),
  }),
  scheduledAt: Joi.date().optional(),
  expiresAt: Joi.date().optional(),
});
