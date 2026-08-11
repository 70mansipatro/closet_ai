import PaymentTransaction from '../../models/PaymentTransaction.js';

const RANGE_DAYS = {
  today: 1,
  '7d': 7,
  '30d': 30,
  '3m': 90,
  '6m': 180,
  '1y': 365,
};

export const resolveRangeToDates = (range) => {
  if (!range || !RANGE_DAYS[range]) return null;
  const to = new Date();
  const from = new Date();
  from.setDate(from.getDate() - RANGE_DAYS[range]);
  return { from, to };
};

const startOfToday = () => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
};

const startOfMonth = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1);
};

const startOfYear = () => {
  const d = new Date();
  return new Date(d.getFullYear(), 0, 1);
};

const sumAmount = async (match) => {
  const result = await PaymentTransaction.aggregate([{ $match: match }, { $group: { _id: null, total: { $sum: '$amount' } } }]);
  return result?.[0]?.total ?? 0;
};

export const getRevenueSummary = async () => {
  const [today, month, year, total, refunds, failedCount, successCount] = await Promise.all([
    sumAmount({ status: 'success', createdAt: { $gte: startOfToday() } }),
    sumAmount({ status: 'success', createdAt: { $gte: startOfMonth() } }),
    sumAmount({ status: 'success', createdAt: { $gte: startOfYear() } }),
    sumAmount({ status: 'success' }),
    sumAmount({ status: 'refunded' }),
    PaymentTransaction.countDocuments({ status: 'failed' }),
    PaymentTransaction.countDocuments({ status: 'success' }),
  ]);

  return {
    today,
    month,
    year,
    grossRevenue: total,
    refunds,
    netRevenue: total - refunds,
    failedPayments: failedCount,
    successfulPayments: successCount,
  };
};

export const getRevenueTrend = async ({ range, from, to, groupBy = 'day' }) => {
  const resolvedRange = resolveRangeToDates(range);
  const effectiveFrom = from ? new Date(from) : resolvedRange?.from;
  const effectiveTo = to ? new Date(to) : resolvedRange?.to;

  const match = { status: 'success' };
  if (effectiveFrom || effectiveTo) {
    match.createdAt = {};
    if (effectiveFrom) match.createdAt.$gte = effectiveFrom;
    if (effectiveTo) match.createdAt.$lte = effectiveTo;
  }

  const dateFormat = groupBy === 'month' ? '%Y-%m' : '%Y-%m-%d';

  const trend = await PaymentTransaction.aggregate([
    { $match: match },
    {
      $group: {
        _id: { $dateToString: { format: dateFormat, date: '$createdAt' } },
        revenue: { $sum: '$amount' },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  return trend.map((entry) => ({ period: entry._id, revenue: entry.revenue, count: entry.count }));
};
