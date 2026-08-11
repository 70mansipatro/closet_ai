import mongoose from 'mongoose';

const announcementSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 150 },
    message: { type: String, required: true, trim: true, maxlength: 1000 },
    priority: { type: String, enum: ['low', 'normal', 'high', 'urgent'], default: 'normal' },
    targetAudience: { type: String, enum: ['all', 'free', 'premium', 'specificUsers'], default: 'all' },
    targetUserIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    status: { type: String, enum: ['scheduled', 'sent', 'cancelled'], default: 'scheduled' },
    scheduledAt: { type: Date, default: () => new Date() },
    expiresAt: { type: Date, default: null },
    sentAt: { type: Date, default: null },
    recipientCount: { type: Number, default: 0 },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true }
);

announcementSchema.index({ status: 1, scheduledAt: 1 });

const Announcement = mongoose.model('Announcement', announcementSchema);
export default Announcement;
