import mongoose from 'mongoose';

export const NOTIFICATION_TYPES = [
  'OUTFIT_REMINDER',
  'LAUNDRY_REMINDER',
  'TRIP_REMINDER',
  'PACKING_REMINDER',
  'WEAR_HISTORY_REMINDER',
  'WARDROBE_REMINDER',
  'AI_STYLIST_REMINDER',
  'SUBSCRIPTION_REMINDER',
  'PREMIUM_EXPIRY',
  'SYSTEM',
  'ADMIN_ANNOUNCEMENT',
  'SMART_REMINDER',
];

export const NOTIFICATION_STATUSES = ['scheduled', 'pending', 'sent', 'read', 'failed', 'cancelled', 'expired'];
export const NOTIFICATION_PRIORITIES = ['low', 'normal', 'high', 'urgent'];
export const NOTIFICATION_CHANNELS = ['IN_APP', 'LOCAL'];

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, enum: NOTIFICATION_TYPES, required: true },
    title: { type: String, required: true, trim: true, maxlength: 150 },
    message: { type: String, required: true, trim: true, maxlength: 500 },
    body: { type: String, trim: true, maxlength: 2000, default: '' },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    channel: { type: [String], enum: NOTIFICATION_CHANNELS, default: ['IN_APP'] },
    priority: { type: String, enum: NOTIFICATION_PRIORITIES, default: 'normal' },
    status: { type: String, enum: NOTIFICATION_STATUSES, default: 'sent' },
    isRead: { type: Boolean, default: false },
    readAt: { type: Date, default: null },
    scheduledAt: { type: Date, default: null },
    sentAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, default: null },
    sourceType: { type: String, trim: true, default: '' },
    sourceId: { type: mongoose.Schema.Types.ObjectId, default: null },
    actionType: { type: String, trim: true, default: '' },
    actionRoute: { type: String, trim: true, default: '' },
  },
  { timestamps: true }
);

notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index({ userId: 1, status: 1 });
notificationSchema.index({ userId: 1, scheduledAt: 1 });
notificationSchema.index({ userId: 1, type: 1 });
notificationSchema.index({ expiresAt: 1 });
notificationSchema.index({ userId: 1, type: 1, sourceId: 1, createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);
export default Notification;
