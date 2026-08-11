import crypto from 'crypto';
import { AppError } from '../utils/appError.js';
import {
  cancelSubscription,
  createOrder,
  getActivePlans,
  getCurrentSubscription,
  getUserSubscriptionStatus,
  restoreSubscription,
  verifyPayment,
} from '../services/subscriptionService.js';
import { createOrderSchema, verifyPaymentSchema } from '../validators/subscriptionValidator.js';

export const getPlansHandler = async (req, res, next) => {
  try {
    const plans = await getActivePlans();
    res.status(200).json({ success: true, data: plans });
  } catch (error) {
    next(error);
  }
};

export const getCurrentSubscriptionHandler = async (req, res, next) => {
  try {
    const userId = req.user?._id || req.user?.userId;
    const current = await getCurrentSubscription(userId);
    const status = await getUserSubscriptionStatus(userId);
    res.status(200).json({ success: true, data: { ...current, ...status, daysRemaining: status?.daysRemaining || 0 } });
  } catch (error) {
    next(error);
  }
};

export const createOrderHandler = async (req, res, next) => {
  try {
    const { error, value } = createOrderSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await createOrder({ userId: req.user._id, planCode: value.planCode });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const verifyPaymentHandler = async (req, res, next) => {
  try {
    const { error, value } = verifyPaymentSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await verifyPayment({
      userId: req.user._id,
      orderId: value.orderId,
      paymentId: value.paymentId,
      signature: value.signature,
      planCode: value.planCode,
    });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const cancelSubscriptionHandler = async (req, res, next) => {
  try {
    const result = await cancelSubscription({ userId: req.user._id });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const restoreSubscriptionHandler = async (req, res, next) => {
  try {
    const result = await restoreSubscription({ userId: req.user._id });
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

export const checkStatusHandler = async (req, res, next) => {
  try {
    const status = await getUserSubscriptionStatus(req.user._id);
    res.status(200).json({ success: true, data: status });
  } catch (error) {
    next(error);
  }
};

export const webhookHandler = async (req, res, next) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const expected = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET || 'test-webhook').update(JSON.stringify(req.body)).digest('hex');
    if (signature !== expected) throw new AppError('Webhook signature invalid', 400, { code: 'UNAUTHORIZED' });

    res.status(200).json({ success: true, message: 'Webhook received' });
  } catch (error) {
    next(error);
  }
};
