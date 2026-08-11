import User from '../../models/User.js';
import Clothing from '../../models/Clothing.js';
import Outfit from '../../models/Outfit.js';
import OutfitCalendar from '../../models/OutfitCalendar.js';
import LaundryHistory from '../../models/LaundryHistory.js';
import Trip from '../../models/Trip.js';
import PackingList from '../../models/PackingList.js';
import FeatureUsage from '../../models/FeatureUsage.js';
import { resolveRangeToDates } from './adminRevenueService.js';

const resolveDates = ({ range, from, to }) => {
  const resolved = resolveRangeToDates(range);
  const effectiveFrom = from ? new Date(from) : resolved?.from;
  const effectiveTo = to ? new Date(to) : resolved?.to;
  if (!effectiveFrom && !effectiveTo) return null;
  const clause = {};
  if (effectiveFrom) clause.$gte = effectiveFrom;
  if (effectiveTo) clause.$lte = effectiveTo;
  return clause;
};

const groupCountByField = async (Model, field, extraMatch = {}) => {
  const results = await Model.aggregate([
    { $match: extraMatch },
    { $group: { _id: { $ifNull: [`$${field}`, 'Unknown'] }, count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  return results.map((item) => ({ label: item._id || 'Unknown', count: item.count }));
};

const growthTrend = async (Model, dateField, dateMatch, groupBy = 'day') => {
  const format = groupBy === 'month' ? '%Y-%m' : '%Y-%m-%d';
  const match = dateMatch ? { [dateField]: dateMatch } : {};
  const trend = await Model.aggregate([
    { $match: match },
    { $group: { _id: { $dateToString: { format, date: `$${dateField}` } }, count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
  ]);
  return trend.map((entry) => ({ period: entry._id, count: entry.count }));
};

export const getUserAnalytics = async ({ range, from, to, groupBy }) => {
  const dateMatch = resolveDates({ range, from, to });
  const [total, active, premium, free, suspended, growth] = await Promise.all([
    User.countDocuments({}),
    User.countDocuments({ status: 'active' }),
    User.countDocuments({ subscriptionStatus: 'active' }),
    User.countDocuments({ subscriptionStatus: { $ne: 'active' } }),
    User.countDocuments({ status: 'suspended' }),
    growthTrend(User, 'createdAt', dateMatch, groupBy),
  ]);
  return { total, active, premium, free, suspended, growth };
};

export const getAiAnalytics = async ({ range, from, to }) => {
  const dateMatch = resolveDates({ range, from, to });
  const match = dateMatch ? { createdAt: dateMatch } : {};

  const [byFeature, byPeriod, totalAgg] = await Promise.all([
    FeatureUsage.aggregate([{ $match: match }, { $group: { _id: '$feature', count: { $sum: '$count' } } }, { $sort: { count: -1 } }]),
    FeatureUsage.aggregate([{ $match: match }, { $group: { _id: '$period', count: { $sum: '$count' } } }, { $sort: { _id: 1 } }]),
    FeatureUsage.aggregate([{ $match: match }, { $group: { _id: null, total: { $sum: '$count' } } }]),
  ]);

  return {
    totalRequests: totalAgg?.[0]?.total ?? 0,
    byFeature: byFeature.map((entry) => ({ feature: entry._id, count: entry.count })),
    byPeriod: byPeriod.map((entry) => ({ period: entry._id, count: entry.count })),
  };
};

export const getWardrobeAnalytics = async ({ range, from, to, groupBy }) => {
  const dateMatch = resolveDates({ range, from, to });
  const [totalItems, byCategory, byColor, byType, growth] = await Promise.all([
    Clothing.countDocuments({}),
    groupCountByField(Clothing, 'category'),
    groupCountByField(Clothing, 'color'),
    groupCountByField(Clothing, 'subCategory'),
    growthTrend(Clothing, 'createdAt', dateMatch, groupBy),
  ]);

  return { totalItems, byCategory, byColor, byType, growth };
};

export const getOutfitAnalytics = async ({ range, from, to, groupBy }) => {
  const dateMatch = resolveDates({ range, from, to });
  const [totalOutfits, favoriteOutfits, byOccasion, plannedCount, wornCount, skippedCount, growth] = await Promise.all([
    Outfit.countDocuments({}),
    Outfit.countDocuments({ favorite: true }),
    groupCountByField(Outfit, 'occasion'),
    OutfitCalendar.countDocuments({ status: 'Planned' }),
    OutfitCalendar.countDocuments({ status: 'Worn' }),
    OutfitCalendar.countDocuments({ status: 'Skipped' }),
    growthTrend(Outfit, 'createdAt', dateMatch, groupBy),
  ]);

  return {
    totalOutfits,
    favoriteOutfits,
    byOccasion,
    planned: plannedCount,
    worn: wornCount,
    skipped: skippedCount,
    growth,
  };
};

export const getLaundryAnalytics = async () => {
  const [byStatus, totalRecords, overdue] = await Promise.all([
    groupCountByField(Clothing, 'laundryStatus'),
    LaundryHistory.countDocuments({}),
    Clothing.countDocuments({ nextWashDueAt: { $lt: new Date() }, laundryStatus: { $ne: 'clean' } }),
  ]);

  return { byStatus, totalHistoryRecords: totalRecords, overdue };
};

export const getTripAnalytics = async () => {
  const now = new Date();
  const [total, upcoming, completed, packingLists, packedItems, unpackedItems, byDestination] = await Promise.all([
    Trip.countDocuments({}),
    Trip.countDocuments({ startDate: { $gte: now } }),
    Trip.countDocuments({ endDate: { $lt: now } }),
    PackingList.aggregate([{ $group: { _id: '$tripId' } }]).then((r) => r.length),
    PackingList.countDocuments({ packed: true }),
    PackingList.countDocuments({ packed: false }),
    groupCountByField(Trip, 'destination'),
  ]);

  return { total, upcoming, completed, packingLists, packedItems, unpackedItems, byDestination: byDestination.slice(0, 10) };
};
