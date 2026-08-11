import mongoose from 'mongoose';

const subscriptionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    planId: { type: mongoose.Schema.Types.ObjectId, ref: 'SubscriptionPlan', default: null },
    planType: { type: String, default: 'free', index: true },
    status: {
      type: String,
      enum: ['pending', 'active', 'cancelled', 'expired', 'past_due', 'failed'],
      default: 'pending',
      index: true,
    },
    paymentProvider: { type: String, default: 'razorpay' },
    providerCustomerId: { type: String, default: '' },
    providerSubscriptionId: { type: String, default: '', index: true },
    providerPaymentId: { type: String, default: '', index: true },
    startDate: { type: Date, default: null },
    endDate: { type: Date, default: null, index: true },
    autoRenew: { type: Boolean, default: true },
    amount: { type: Number, default: 0 },
    currency: { type: String, default: 'INR' },
    cancelledAt: { type: Date, default: null },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

subscriptionSchema.index({ userId: 1, status: 1 });

const Subscription = mongoose.model('Subscription', subscriptionSchema);
export default Subscription;
