import mongoose from 'mongoose';

const featureUsageSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    feature: { type: String, required: true, trim: true, index: true },
    period: { type: String, required: true, trim: true, index: true },
    count: { type: Number, default: 0 },
    periodStart: { type: Date, required: true, index: true },
    periodEnd: { type: Date, required: true, index: true },
  },
  { timestamps: true }
);

featureUsageSchema.index({ userId: 1, feature: 1, period: 1 }, { unique: true });

const FeatureUsage = mongoose.model('FeatureUsage', featureUsageSchema);
export default FeatureUsage;
