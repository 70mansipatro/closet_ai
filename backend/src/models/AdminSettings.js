import mongoose from 'mongoose';

const adminSettingsSchema = new mongoose.Schema(
  {
    maintenanceMode: {
      enabled: { type: Boolean, default: false },
      message: { type: String, default: '', maxlength: 500 },
    },
    notifications: {
      announcementBanner: { type: String, default: '', maxlength: 500 },
      templatesPlaceholder: { type: mongoose.Schema.Types.Mixed, default: {} },
    },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  },
  { timestamps: true }
);

const AdminSettings = mongoose.model('AdminSettings', adminSettingsSchema);
export default AdminSettings;
