import User from '../../models/User.js';
import Subscription from '../../models/Subscription.js';
import Clothing from '../../models/Clothing.js';
import Outfit from '../../models/Outfit.js';
import Trip from '../../models/Trip.js';
import LaundryHistory from '../../models/LaundryHistory.js';
import FeatureUsage from '../../models/FeatureUsage.js';
import { getRevenueSummary, resolveRangeToDates } from './adminRevenueService.js';

export const getDashboardSummary = async ({ range } = {}) => {
  const resolvedRange = resolveRangeToDates(range);
  const rangeMatch = resolvedRange ? { createdAt: { $gte: resolvedRange.from, $lte: resolvedRange.to } } : {};

  const [
    totalUsers,
    activeUsers,
    premiumUsers,
    suspendedUsers,
    activeSubscriptions,
    expiredSubscriptions,
    revenue,
    wardrobeItems,
    outfitsCreated,
    tripsCreated,
    laundryRecords,
    aiRequests,
    newUsersInRange,
  ] = await Promise.all([
    User.countDocuments({}),
    User.countDocuments({ status: 'active' }),
    User.countDocuments({ subscriptionStatus: 'active' }),
    User.countDocuments({ status: 'suspended' }),
    Subscription.countDocuments({ status: 'active' }),
    Subscription.countDocuments({ status: 'expired' }),
    getRevenueSummary(),
    Clothing.countDocuments({}),
    Outfit.countDocuments({}),
    Trip.countDocuments({}),
    LaundryHistory.countDocuments({}),
    FeatureUsage.aggregate([{ $group: { _id: null, total: { $sum: '$count' } } }]),
    Object.keys(rangeMatch).length ? User.countDocuments(rangeMatch) : Promise.resolve(null),
  ]);

  return {
    users: {
      total: totalUsers,
      active: activeUsers,
      premium: premiumUsers,
      free: Math.max(totalUsers - premiumUsers, 0),
      suspended: suspendedUsers,
      newInRange: newUsersInRange,
    },
    subscriptions: {
      active: activeSubscriptions,
      expired: expiredSubscriptions,
    },
    payments: {
      successful: revenue.successfulPayments,
      failed: revenue.failedPayments,
    },
    revenue: {
      today: revenue.today,
      month: revenue.month,
      year: revenue.year,
      gross: revenue.grossRevenue,
      refunds: revenue.refunds,
      net: revenue.netRevenue,
    },
    ai: {
      totalRequests: aiRequests?.[0]?.total ?? 0,
    },
    content: {
      wardrobeItems,
      outfitsCreated,
      tripsCreated,
      laundryRecords,
    },
  };
};
