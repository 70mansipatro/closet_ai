import mongoose from 'mongoose';

const adminAuditLogSchema = new mongoose.Schema(
  {
    adminUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    action: { type: String, required: true, trim: true, index: true },
    targetType: { type: String, default: '', trim: true },
    targetId: { type: String, default: '', trim: true },
    description: { type: String, default: '', maxlength: 1000 },
    ipAddress: { type: String, default: '' },
    userAgent: { type: String, default: '' },
  },
  { timestamps: true }
);

adminAuditLogSchema.index({ targetType: 1, targetId: 1 });
adminAuditLogSchema.index({ createdAt: -1 });

const AdminAuditLog = mongoose.model('AdminAuditLog', adminAuditLogSchema);
export default AdminAuditLog;
