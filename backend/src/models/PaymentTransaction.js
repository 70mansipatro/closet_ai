import mongoose from 'mongoose';

const paymentTransactionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    subscriptionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subscription', default: null, index: true },
    provider: { type: String, default: 'razorpay' },
    orderId: { type: String, required: true, index: true },
    paymentId: { type: String, default: '', index: true },
    signature: { type: String, default: '' },
    amount: { type: Number, default: 0 },
    currency: { type: String, default: 'INR' },
    status: {
      type: String,
      enum: ['created', 'pending', 'success', 'failed', 'refunded'],
      default: 'created',
      index: true,
    },
    failureReason: { type: String, default: '' },
  },
  { timestamps: true }
);

paymentTransactionSchema.index({ orderId: 1, paymentId: 1 });

const PaymentTransaction = mongoose.model('PaymentTransaction', paymentTransactionSchema);
export default PaymentTransaction;
