import mongoose from 'mongoose';

const smartReminderSettingSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    enabled: { type: Boolean, default: true },
    smartOutfit: { type: Boolean, default: true },
    smartLaundry: { type: Boolean, default: true },
    smartPacking: { type: Boolean, default: true },
    smartTrip: { type: Boolean, default: true },
    smartWardrobe: { type: Boolean, default: true },
    smartWearHistory: { type: Boolean, default: true },
    smartAIStylist: { type: Boolean, default: true },
    maxDailyReminders: { type: Number, default: 3, min: 0, max: 20 },
    minimumIntervalMinutes: { type: Number, default: 120, min: 0, max: 1440 },
    quietHoursEnabled: { type: Boolean, default: false },
  },
  { timestamps: true }
);

const SmartReminderSetting = mongoose.model('SmartReminderSetting', smartReminderSettingSchema);
export default SmartReminderSetting;
