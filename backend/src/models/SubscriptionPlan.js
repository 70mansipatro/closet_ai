import mongoose from 'mongoose';

const subscriptionPlanSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    planCode: { type: String, required: true, unique: true, index: true, trim: true },
    description: { type: String, default: '' },
    price: { type: Number, required: true, default: 0 },
    currency: { type: String, default: 'INR', uppercase: true },
    billingPeriod: { type: String, default: 'none' },
    features: { type: [String], default: [] },
    limits: { type: mongoose.Schema.Types.Mixed, default: {} },
    isActive: { type: Boolean, default: true, index: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const SubscriptionPlan = mongoose.model('SubscriptionPlan', subscriptionPlanSchema);
export default SubscriptionPlan;
