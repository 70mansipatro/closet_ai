import mongoose from 'mongoose';

const notificationPreferenceSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    outfitReminders: { type: Boolean, default: true },
    laundryReminders: { type: Boolean, default: true },
    tripReminders: { type: Boolean, default: true },
    packingReminders: { type: Boolean, default: true },
    wearHistoryReminders: { type: Boolean, default: true },
    wardrobeReminders: { type: Boolean, default: true },
    aiStylistReminders: { type: Boolean, default: true },
    subscriptionReminders: { type: Boolean, default: true },
    premiumExpiryReminders: { type: Boolean, default: true },
    smartReminders: { type: Boolean, default: true },
    adminAnnouncements: { type: Boolean, default: true },
    inAppEnabled: { type: Boolean, default: true },
    localEnabled: { type: Boolean, default: true },
    quietHoursEnabled: { type: Boolean, default: false },
    quietHoursStart: { type: String, trim: true, default: '22:00' },
    quietHoursEnd: { type: String, trim: true, default: '07:00' },
    timezone: { type: String, trim: true, default: 'UTC' },
  },
  { timestamps: true }
);

const NotificationPreference = mongoose.model('NotificationPreference', notificationPreferenceSchema);
export default NotificationPreference;
