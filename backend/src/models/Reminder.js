import mongoose from 'mongoose';

export const REMINDER_TYPES = [
  'OUTFIT_REMINDER',
  'LAUNDRY_REMINDER',
  'TRIP_REMINDER',
  'PACKING_REMINDER',
  'WEAR_HISTORY_REMINDER',
  'WARDROBE_REMINDER',
  'AI_STYLIST_REMINDER',
  'SUBSCRIPTION_REMINDER',
  'CUSTOM',
];

export const REMINDER_FREQUENCIES = ['once', 'daily', 'weekly', 'monthly', 'smart'];
export const REMINDER_PRIORITIES = ['low', 'normal', 'high', 'urgent'];

const reminderSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, enum: REMINDER_TYPES, required: true },
    title: { type: String, required: true, trim: true, maxlength: 150 },
    description: { type: String, trim: true, maxlength: 1000, default: '' },
    enabled: { type: Boolean, default: true },
    frequency: { type: String, enum: REMINDER_FREQUENCIES, default: 'once' },
    scheduledTime: { type: String, trim: true, default: '' },
    daysOfWeek: { type: [Number], default: [] },
    date: { type: Date, default: null },
    startDate: { type: Date, default: null },
    endDate: { type: Date, default: null },
    timezone: { type: String, trim: true, default: 'UTC' },
    sourceType: { type: String, trim: true, default: '' },
    sourceId: { type: mongoose.Schema.Types.ObjectId, default: null },
    priority: { type: String, enum: REMINDER_PRIORITIES, default: 'normal' },
    snoozeMinutes: { type: Number, default: 0 },
    smartEnabled: { type: Boolean, default: false },
    lastTriggeredAt: { type: Date, default: null },
    nextTriggerAt: { type: Date, default: null, index: true },
  },
  { timestamps: true }
);

reminderSchema.index({ userId: 1, nextTriggerAt: 1 });
reminderSchema.index({ userId: 1, sourceType: 1, sourceId: 1 });
reminderSchema.index({ userId: 1, type: 1 });

const Reminder = mongoose.model('Reminder', reminderSchema);
export default Reminder;
