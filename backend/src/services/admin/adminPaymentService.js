import PaymentTransaction from '../../models/PaymentTransaction.js';
import User from '../../models/User.js';
import { AppError } from '../../utils/appError.js';

const buildDateRange = (from, to) => {
  if (!from && !to) return null;
  const range = {};
  if (from) range.$gte = new Date(from);
  if (to) range.$lte = new Date(to);
  return range;
};

export const listPayments = async ({ page = 1, limit = 20, status, provider, search, from, to }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const match = {};
  if (status) match.status = status;
  if (provider) match.provider = provider;
  const dateRange = buildDateRange(from, to);
  if (dateRange) match.createdAt = dateRange;

  if (search) {
    const regex = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    const matchingUsers = await User.find({ $or: [{ name: regex }, { email: regex }] }).select('_id').lean();
    match.$or = [{ orderId: regex }, { paymentId: regex }, { userId: { $in: matchingUsers.map((u) => u._id) } }];
  }

  const [items, total] = await Promise.all([
    PaymentTransaction.find(match)
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate('userId', 'name email')
      .lean(),
    PaymentTransaction.countDocuments(match),
  ]);

  return {
    items,
    page: safePage,
    limit: safeLimit,
    total,
    totalPages: Math.max(Math.ceil(total / safeLimit), 1),
  };
};

export const getPaymentDetail = async (id) => {
  const payment = await PaymentTransaction.findById(id).populate('userId', 'name email').lean();
  if (!payment) throw new AppError('Payment not found', 404, { code: 'PAYMENT_NOT_FOUND' });
  return payment;
};
