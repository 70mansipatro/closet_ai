import Subscription from '../../models/Subscription.js';
import User from '../../models/User.js';
import { AppError } from '../../utils/appError.js';

export const listSubscriptions = async ({ page = 1, limit = 20, status, plan, search }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const match = {};
  if (status) match.status = status;
  if (plan) match.planType = plan;

  if (search) {
    const regex = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    const matchingUsers = await User.find({ $or: [{ name: regex }, { email: regex }] }).select('_id').lean();
    match.userId = { $in: matchingUsers.map((u) => u._id) };
  }

  const [items, total] = await Promise.all([
    Subscription.find(match)
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate('userId', 'name email')
      .populate('planId', 'name planCode price billingPeriod')
      .lean(),
    Subscription.countDocuments(match),
  ]);

  return {
    items,
    page: safePage,
    limit: safeLimit,
    total,
    totalPages: Math.max(Math.ceil(total / safeLimit), 1),
  };
};

export const getSubscriptionDetail = async (id) => {
  const subscription = await Subscription.findById(id)
    .populate('userId', 'name email role status')
    .populate('planId', 'name planCode price billingPeriod features limits')
    .lean();
  if (!subscription) throw new AppError('Subscription not found', 404, { code: 'SUBSCRIPTION_NOT_FOUND' });
  return subscription;
};
