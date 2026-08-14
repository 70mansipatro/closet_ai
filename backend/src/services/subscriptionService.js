import crypto from 'crypto';
import SubscriptionPlan from '../models/SubscriptionPlan.js';
import Subscription from '../models/Subscription.js';
import PaymentTransaction from '../models/PaymentTransaction.js';
import FeatureUsage from '../models/FeatureUsage.js';
import User from '../models/User.js';
import { AppError } from '../utils/appError.js';

const DEFAULT_FREE_LIMITS = {
  wardrobe: 50,
  ai_outfit: 10,
  ai_stylist: 20,
  trip: 2,
  analytics: 1,
};

const DEFAULT_PREMIUM_LIMITS = {
  wardrobe: Infinity,
  ai_outfit: Infinity,
  ai_stylist: Infinity,
  trip: Infinity,
  analytics: Infinity,
};

export const buildDefaultSubscriptionPlans = () => [
  {
    name: 'Free',
    planCode: 'free',
    description: 'Basic wardrobe and AI access',
    price: 0,
    currency: 'INR',
    billingPeriod: 'none',
    features: ['basic_wardrobe', 'basic_analytics', 'limited_ai'],
    limits: DEFAULT_FREE_LIMITS,
    isActive: true,
    sortOrder: 0,
  },
  {
    name: 'Premium Monthly',
    planCode: 'premium_monthly',
    description: 'Unlock premium features with monthly billing',
    price: 199,
    currency: 'INR',
    billingPeriod: 'monthly',
    features: ['unlimited_wardrobe', 'advanced_ai', 'advanced_analytics', 'smart_outfits', 'packing_assistant'],
    limits: DEFAULT_PREMIUM_LIMITS,
    isActive: true,
    sortOrder: 1,
  },
  {
    name: 'Premium Yearly',
    planCode: 'premium_yearly',
    description: 'Unlock premium features with annual billing',
    price: 1499,
    currency: 'INR',
    billingPeriod: 'yearly',
    features: ['unlimited_wardrobe', 'advanced_ai', 'advanced_analytics', 'smart_outfits', 'packing_assistant'],
    limits: DEFAULT_PREMIUM_LIMITS,
    isActive: true,
    sortOrder: 2,
  },
];

const normalizePlan = (plan) => ({
  planCode: plan.planCode,
  name: plan.name,
  price: plan.price,
  currency: plan.currency,
  billingPeriod: plan.billingPeriod,
  features: plan.features || [],
  limits: plan.limits || {},
});

export const bootstrapSubscriptionPlans = async () => {
  const plans = buildDefaultSubscriptionPlans();
  for (const plan of plans) {
    await SubscriptionPlan.findOneAndUpdate(
      { planCode: plan.planCode },
      { $setOnInsert: { ...plan } },
      { upsert: true, new: true }
    );
  }
};

export const getActivePlans = async () => {
  const plans = await SubscriptionPlan.find({ isActive: true }).sort({ sortOrder: 1, price: 1 });
  return plans.map(normalizePlan);
};

export const getPlanByCode = async (planCode) => {
  return SubscriptionPlan.findOne({ planCode, isActive: true });
};

export const getUserSubscriptionStatus = async (userId) => {
  const user = await User.findById(userId).lean();
  if (!user) return null;

  const subscription = await Subscription.findOne({ userId }).sort({ createdAt: -1 }).lean();
  const now = new Date();
  const effectiveStatus = subscription?.endDate && new Date(subscription.endDate) < now ? 'expired' : subscription?.status || 'free';
  const isEntitled = effectiveStatus === 'active' && (!subscription?.endDate || new Date(subscription.endDate) >= now);
  return {
    plan: user.subscriptionPlan || 'free',
    status: effectiveStatus,
    startDate: subscription?.startDate || null,
    endDate: subscription?.endDate || null,
    autoRenew: subscription?.autoRenew ?? false,
    isEntitled,
    daysRemaining: subscription?.endDate ? Math.max(0, Math.ceil((new Date(subscription.endDate) - now) / (1000 * 60 * 60 * 24))) : 0,
  };
};

export const createOrder = async ({ userId, planCode }) => {
  const plan = await getPlanByCode(planCode);
  if (!plan) throw new AppError('Invalid plan', 400, { code: 'INVALID_PLAN' });
  if (plan.price <= 0) throw new AppError('This plan does not require payment', 400, { code: 'INVALID_PLAN' });

  const transaction = await PaymentTransaction.create({
    userId,
    orderId: `order_${Date.now()}_${Math.round(Math.random() * 1e6)}`,
    amount: plan.price,
    currency: plan.currency,
    status: 'created',
  });

  return {
    success: true,
    data: {
      orderId: transaction.orderId,
      amount: plan.price * 100,
      currency: plan.currency,
      keyId: process.env.RAZORPAY_KEY_ID || 'test-key',
    },
  };
};

export const verifyPayment = async ({ userId, orderId, paymentId, signature, planCode }) => {
  const existing = await PaymentTransaction.findOne({ orderId, userId }).lean();
  if (!existing) throw new AppError('Order not found', 404, { code: 'ORDER_NOT_FOUND' });
  if (existing.status === 'success') {
    return { success: true, data: { alreadyVerified: true, message: 'Payment already verified' } };
  }

  const plan = await getPlanByCode(planCode);
  if (!plan) throw new AppError('Invalid plan', 400, { code: 'INVALID_PLAN' });

  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'test-secret')
    .update(`${existing.orderId}|${paymentId}`)
    .digest('hex');

  if (expectedSignature !== signature) {
    await PaymentTransaction.findByIdAndUpdate(existing._id, { status: 'failed', failureReason: 'Invalid signature' });
    throw new AppError('Payment verification failed', 400, { code: 'PAYMENT_VERIFICATION_FAILED' });
  }

  const subscription = await Subscription.findOne({ userId, providerPaymentId: paymentId }).lean();
  if (subscription && subscription.status === 'active') {
    return { success: true, data: { message: 'Subscription already active' } };
  }

  const now = new Date();
  const endDate = new Date(now);
  if (plan.billingPeriod === 'monthly') {
    endDate.setMonth(endDate.getMonth() + 1);
  } else if (plan.billingPeriod === 'yearly') {
    endDate.setFullYear(endDate.getFullYear() + 1);
  }

  const newSubscription = await Subscription.findOneAndUpdate(
    { userId, providerPaymentId: paymentId },
    {
      $setOnInsert: {
        userId,
        planId: plan._id,
        planType: plan.planCode,
        status: 'active',
        paymentProvider: 'razorpay',
        providerPaymentId: paymentId,
        startDate: now,
        endDate,
        autoRenew: true,
        amount: plan.price,
        currency: plan.currency,
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  await User.findByIdAndUpdate(userId, {
    subscriptionStatus: 'active',
    subscriptionPlan: plan.planCode,
    subscriptionStartDate: now,
    subscriptionEndDate: endDate,
    autoRenew: true,
  });

  await PaymentTransaction.findByIdAndUpdate(existing._id, {
    status: 'success',
    paymentId,
    signature,
    subscriptionId: newSubscription._id,
  });

  return { success: true, data: { subscriptionId: newSubscription._id, planCode: plan.planCode, status: 'active', endDate } };
};

export const cancelSubscription = async ({ userId }) => {
  const subscription = await Subscription.findOne({ userId }).sort({ createdAt: -1 });
  if (!subscription) throw new AppError('Subscription not found', 404, { code: 'SUBSCRIPTION_NOT_FOUND' });

  subscription.autoRenew = false;
  subscription.status = 'cancelled';
  subscription.cancelledAt = new Date();
  await subscription.save();

  await User.findByIdAndUpdate(userId, {
    subscriptionStatus: 'cancelled',
    autoRenew: false,
  });

  return { success: true, data: { message: 'Subscription cancellation requested', autoRenew: false } };
};

export const restoreSubscription = async ({ userId }) => {
  const subscription = await Subscription.findOne({ userId, status: 'cancelled' }).sort({ createdAt: -1 });
  if (!subscription) throw new AppError('No active subscription found.', 404, { code: 'SUBSCRIPTION_NOT_FOUND' });

  subscription.autoRenew = true;
  subscription.status = 'active';
  await subscription.save();
  await User.findByIdAndUpdate(userId, { subscriptionStatus: 'active', autoRenew: true });
  return { success: true, data: { message: 'Subscription restored' } };
};

export const getCurrentSubscription = async (userId) => {
  const user = await User.findById(userId).lean();
  const subscription = await Subscription.findOne({ userId }).sort({ createdAt: -1 }).lean();
  if (!subscription) return { plan: user?.subscriptionPlan || 'free', status: user?.subscriptionStatus || 'free', startDate: user?.subscriptionStartDate || null, endDate: user?.subscriptionEndDate || null, autoRenew: user?.autoRenew || false };
  return {
    plan: subscription.planType || 'free',
    status: subscription.status,
    startDate: subscription.startDate,
    endDate: subscription.endDate,
    autoRenew: subscription.autoRenew,
  };
};

export const getFeatureUsage = async ({ userId, feature }) => {
  const user = await User.findById(userId).lean();
  const status = await getUserSubscriptionStatus(userId);
  const isPremium = Boolean(status?.isEntitled);
  const period = new Date().toISOString().slice(0, 7);
  const now = new Date();
  const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

  let record = await FeatureUsage.findOne({ userId, feature, period }).lean();
  if (!record) {
    record = await FeatureUsage.create({ userId, feature, period, periodStart, periodEnd, count: 0 });
  }

  const limits = isPremium ? DEFAULT_PREMIUM_LIMITS : DEFAULT_FREE_LIMITS;
  const limit = limits[feature] ?? (isPremium ? Infinity : 0);
  return { count: record.count || 0, limit, isPremium, recordId: record._id };
};

export const incrementFeatureUsage = async ({ userId, feature, isPremium = false }) => {
  const now = new Date();
  const period = now.toISOString().slice(0, 7);
  const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  const record = await FeatureUsage.findOneAndUpdate(
    { userId, feature, period },
    { $setOnInsert: { userId, feature, period, periodStart, periodEnd }, $inc: { count: 1 } },
    { upsert: true, new: true }
  );
  return { feature, count: record.count, isPremium };
};

export const getFeatureUsageSummary = async (userId) => {
  const usage = await FeatureUsage.find({ userId }).lean();
  return usage.map((entry) => ({ feature: entry.feature, count: entry.count, period: entry.period }));
};
