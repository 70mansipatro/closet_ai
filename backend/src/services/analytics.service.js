import mongoose from 'mongoose';
import Clothing from '../models/Clothing.js';
import WearHistory from '../models/WearHistory.js';
import OutfitCalendar from '../models/OutfitCalendar.js';
import LaundryHistory from '../models/LaundryHistory.js';
import Outfit from '../models/Outfit.js';
import { AppError } from '../utils/appError.js';

const normalizeRange = ({ from, to }) => {
  if (!from && !to) return null;
  const range = {};
  if (from) {
    const start = new Date(from);
    if (Number.isNaN(start.getTime())) throw new AppError('Invalid from date', 400);
    start.setHours(0, 0, 0, 0);
    range.$gte = start;
  }
  if (to) {
    const end = new Date(to);
    if (Number.isNaN(end.getTime())) throw new AppError('Invalid to date', 400);
    end.setHours(23, 59, 59, 999);
    range.$lte = end;
  }
  return range;
};

const buildMatch = ({ userId, from, to, dateField = 'date' }) => {
  const match = { userId };
  const dateRange = normalizeRange({ from, to });
  if (dateRange) match[dateField] = dateRange;
  return match;
};

const safeNumber = (value) => (typeof value === 'number' && !Number.isNaN(value) ? value : 0);

export const getAnalyticsOverview = async ({ userId, from, to }) => {
  const wardrobeCount = await Clothing.countDocuments({ userId });
  const unusedItems = await Clothing.countDocuments({ userId, $or: [{ wearCount: 0 }, { wearCount: { $exists: false } }] });
  const wardrobeValueAgg = await Clothing.aggregate([
    { $match: { userId, purchasePrice: { $gt: 0 } } },
    { $group: { _id: null, totalValue: { $sum: '$purchasePrice' } } },
  ]);
  const wardrobeValue = wardrobeValueAgg?.[0]?.totalValue ?? 0;

  const wearMatch = buildMatch({ userId, from, to, dateField: 'date' });
  const totalWears = await WearHistory.countDocuments(wearMatch);
  const uniqueItemsWorn = (await WearHistory.distinct('clothingId', wearMatch)).length;

  const calendarMatch = buildMatch({ userId, from, to, dateField: 'date' });
  const plannedOutfits = await OutfitCalendar.countDocuments({ ...calendarMatch, status: 'Planned' });
  const wornOutfits = await OutfitCalendar.countDocuments({ ...calendarMatch, status: 'Worn' });

  const laundryItems = await Clothing.countDocuments({ userId, laundryStatus: { $in: ['dirty', 'washing', 'drying', 'ironing', 'in-use'] } });

  const averageWearsPerItem = wardrobeCount > 0 ? Number((totalWears / wardrobeCount).toFixed(2)) : 0;
  const averageCostPerWear = totalWears > 0 ? Number((wardrobeValue / totalWears).toFixed(2)) : 0;

  return {
    wardrobeCount,
    totalWears,
    uniqueItemsWorn,
    plannedOutfits,
    wornOutfits,
    laundryItems,
    unusedItems,
    averageWearsPerItem,
    wardrobeValue,
    averageCostPerWear,
  };
};

const buildInventoryAggregation = async ({ userId, field, label }) => {
  const results = await Clothing.aggregate([
    { $match: { userId } },
    {
      $group: {
        _id: { $ifNull: [`$${field}`, 'Unknown'] },
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1, '_id': 1 } },
  ]);
  return results.map((item) => ({ label: item._id || 'Unknown', count: item.count }));
};

export const getWardrobeAnalytics = async ({ userId }) => {
  const totalItems = await Clothing.countDocuments({ userId });
  const wardrobeValueAgg = await Clothing.aggregate([
    { $match: { userId, purchasePrice: { $gt: 0 } } },
    { $group: { _id: null, totalValue: { $sum: '$purchasePrice' } } },
  ]);
  const wardrobeValue = wardrobeValueAgg?.[0]?.totalValue ?? 0;

  return {
    totalItems,
    wardrobeValue,
    itemsByCategory: await buildInventoryAggregation({ userId, field: 'category' }),
    itemsByColor: await buildInventoryAggregation({ userId, field: 'color' }),
    itemsBySeason: await buildInventoryAggregation({ userId, field: 'season' }),
    itemsByOccasion: await buildInventoryAggregation({ userId, field: 'occasion' }),
    itemsByBrand: await buildInventoryAggregation({ userId, field: 'brand' }),
    itemsByMaterial: await buildInventoryAggregation({ userId, field: 'fabric' }),
    itemsByLaundryStatus: await buildInventoryAggregation({ userId, field: 'laundryStatus' }),
    itemsByAvailability: [
      {
        label: 'Available',
        count: await Clothing.countDocuments({ userId, laundryStatus: { $in: ['clean', 'ready'] } }),
      },
      {
        label: 'Unavailable',
        count: await Clothing.countDocuments({ userId, laundryStatus: { $in: ['dirty', 'washing', 'drying', 'ironing', 'in-use', 'repair'] } }),
      },
    ],
  };
};

export const getWearAnalytics = async ({ userId, from, to }) => {
  const wearMatch = buildMatch({ userId, from, to, dateField: 'date' });
  const totalWears = await WearHistory.countDocuments(wearMatch);
  const uniqueItemsWorn = (await WearHistory.distinct('clothingId', wearMatch)).length;
  const totalItems = await Clothing.countDocuments({ userId });
  const averageWearsPerItem = totalItems > 0 ? Number((totalWears / totalItems).toFixed(2)) : 0;

  const mostWornItems = await Clothing.find({ userId }).sort({ wearCount: -1 }).limit(5).lean();
  const leastWornItems = await Clothing.find({ userId }).sort({ wearCount: 1 }).limit(5).lean();
  const neverWornItems = await Clothing.find({ userId, $or: [{ wearCount: 0 }, { wearCount: { $exists: false } }] }).limit(10).lean();
  const recentlyWornItems = await Clothing.find({ userId, lastWorn: { $exists: true } }).sort({ lastWorn: -1 }).limit(5).lean();

  const datePeriods = [
    { unit: 'day', format: '%Y-%m-%d', label: 'date' },
    { unit: 'week', format: '%G-%V', label: 'week' },
    { unit: 'month', format: '%Y-%m', label: 'month' },
  ];

  const wearByPeriod = await Promise.all(
    datePeriods.map(async ({ format, label }) => {
      const agg = await WearHistory.aggregate([
        { $match: wearMatch },
        {
          $group: {
            _id: { $dateToString: { format, date: '$date' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]);
      return {
        label,
        values: agg.map((item) => ({ period: item._id, count: item.count })),
      };
    }),
  );

  return {
    totalWears,
    uniqueItemsWorn,
    averageWearsPerItem,
    mostWornItems: mostWornItems.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      image: item.imageUrl || '',
      category: item.category || 'other',
      color: item.color || '',
      wearCount: safeNumber(item.wearCount),
      lastWorn: item.lastWorn || null,
      purchasePrice: safeNumber(item.purchasePrice),
      costPerWear: item.wearCount > 0 ? Number((safeNumber(item.purchasePrice) / item.wearCount).toFixed(2)) : null,
    })),
    leastWornItems: leastWornItems.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      image: item.imageUrl || '',
      category: item.category || 'other',
      color: item.color || '',
      wearCount: safeNumber(item.wearCount),
      lastWorn: item.lastWorn || null,
      purchasePrice: safeNumber(item.purchasePrice),
    })),
    neverWornItems: neverWornItems.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      image: item.imageUrl || '',
      category: item.category || 'other',
      dateAdded: item.createdAt || null,
      purchasePrice: safeNumber(item.purchasePrice),
    })),
    recentlyWornItems: recentlyWornItems.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      image: item.imageUrl || '',
      lastWorn: item.lastWorn || null,
    })),
    wearCountByDay: wearByPeriod.find((item) => item.label === 'date')?.values ?? [],
    wearCountByWeek: wearByPeriod.find((item) => item.label === 'week')?.values ?? [],
    wearCountByMonth: wearByPeriod.find((item) => item.label === 'month')?.values ?? [],
  };
};

const lookupOutfits = async (aggregation) => {
  const items = await Outfit.find({ _id: { $in: aggregation.map((item) => item._id).filter(Boolean) } }).lean();
  const itemMap = new Map(items.map((item) => [String(item._id), item]));
  return aggregation.map((item) => ({
    outfitId: item._id,
    count: item.count,
    outfit: itemMap.get(String(item._id)) || null,
  }));
};

export const getOutfitAnalytics = async ({ userId, from, to }) => {
  const calendarMatch = buildMatch({ userId, from, to, dateField: 'date' });
  const totalOutfits = await Outfit.countDocuments({ userId });
  const plannedOutfits = await OutfitCalendar.countDocuments({ ...calendarMatch, status: 'Planned' });
  const wornOutfits = await OutfitCalendar.countDocuments({ ...calendarMatch, status: 'Worn' });
  const skippedOutfits = await OutfitCalendar.countDocuments({ ...calendarMatch, status: 'Skipped' });
  const completionBase = plannedOutfits + wornOutfits + skippedOutfits;
  const completionRate = completionBase > 0 ? Number(((wornOutfits / completionBase) * 100).toFixed(0)) : 0;

  const mostWorn = await OutfitCalendar.aggregate([
    { $match: { ...calendarMatch, outfitId: { $exists: true, $ne: null } } },
    { $group: { _id: '$outfitId', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);
  const mostPlanned = await OutfitCalendar.aggregate([
    { $match: { ...calendarMatch, status: 'Planned', outfitId: { $exists: true, $ne: null } } },
    { $group: { _id: '$outfitId', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);
  const mostSkipped = await OutfitCalendar.aggregate([
    { $match: { ...calendarMatch, status: 'Skipped', outfitId: { $exists: true, $ne: null } } },
    { $group: { _id: '$outfitId', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);

  const [wornSeries, plannedSeries] = await Promise.all([
    OutfitCalendar.aggregate([
      { $match: { ...calendarMatch, status: 'Worn' } },
      { $group: { _id: { $dateToString: { format: '%Y-%m', date: '$date' } }, count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]),
    OutfitCalendar.aggregate([
      { $match: { ...calendarMatch, status: 'Planned' } },
      { $group: { _id: { $dateToString: { format: '%Y-%m', date: '$date' } }, count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]),
  ]);

  return {
    totalOutfits,
    plannedOutfits,
    wornOutfits,
    skippedOutfits,
    completionRate,
    mostWornOutfits: await lookupOutfits(mostWorn),
    mostPlannedOutfits: await lookupOutfits(mostPlanned),
    mostSkippedOutfits: await lookupOutfits(mostSkipped),
    plannedVsWornByMonth: {
      planned: plannedSeries.map((item) => ({ period: item._id, count: item.count })),
      worn: wornSeries.map((item) => ({ period: item._id, count: item.count })),
    },
  };
};

export const getCategoryAnalytics = async ({ userId, from, to }) => {
  const match = buildMatch({ userId, from, to, dateField: 'date' });
  const categories = await WearHistory.aggregate([
    { $match: match },
    { $lookup: { from: 'clothings', localField: 'clothingId', foreignField: '_id', as: 'item' } },
    { $unwind: '$item' },
    { $group: { _id: '$item.category', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  return categories.map((entry) => ({ category: entry._id || 'Unknown', wearCount: entry.count }));
};

export const getColorAnalytics = async ({ userId, from, to }) => {
  const match = buildMatch({ userId, from, to, dateField: 'date' });
  const colorAgg = await WearHistory.aggregate([
    { $match: match },
    { $lookup: { from: 'clothings', localField: 'clothingId', foreignField: '_id', as: 'item' } },
    { $unwind: '$item' },
    { $group: { _id: '$item.color', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  const total = colorAgg.reduce((sum, item) => sum + item.count, 0);
  return colorAgg.map((entry) => ({ color: entry._id || 'Unknown', count: entry.count, percentage: total > 0 ? Number(((entry.count / total) * 100).toFixed(1)) : 0 }));
};

export const getBrandAnalytics = async ({ userId, from, to }) => {
  const owned = await Clothing.aggregate([
    { $match: { userId, brand: { $exists: true, $ne: '' } } },
    { $group: { _id: '$brand', itemCount: { $sum: 1 }, wearCount: { $sum: '$wearCount' } } },
    { $addFields: { averageWearCount: { $cond: [{ $gt: ['$itemCount', 0] }, { $divide: ['$wearCount', '$itemCount'] }, 0] } } },
    { $sort: { wearCount: -1 } },
  ]);

  const mostOwnedBrands = owned.slice(0, 5);
  const mostWornBrands = owned.slice(0, 5);
  const leastWornBrands = [...owned].reverse().slice(0, 5);

  return {
    mostOwnedBrands: mostOwnedBrands.map((entry) => ({ brand: entry._id, itemCount: entry.itemCount, wearCount: entry.wearCount, averageWearCount: Number(entry.averageWearCount.toFixed(2)) })),
    mostWornBrands: mostWornBrands.map((entry) => ({ brand: entry._id, itemCount: entry.itemCount, wearCount: entry.wearCount, averageWearCount: Number(entry.averageWearCount.toFixed(2)) })),
    leastWornBrands: leastWornBrands.map((entry) => ({ brand: entry._id, itemCount: entry.itemCount, wearCount: entry.wearCount, averageWearCount: Number(entry.averageWearCount.toFixed(2)) })),
    averageWearCountByBrand: owned.map((entry) => ({ brand: entry._id, averageWearCount: Number(entry.averageWearCount.toFixed(2)) })),
  };
};

export const getLaundryAnalytics = async ({ userId, from, to }) => {
  const rangeMatch = normalizeRange({ from, to });
  const historyMatch = { userId };
  if (rangeMatch) historyMatch.changedAt = rangeMatch;

  const totalLaundryCycles = await LaundryHistory.countDocuments(historyMatch);
  const currentlyDirty = await Clothing.countDocuments({ userId, laundryStatus: 'dirty' });
  const currentlyWashing = await Clothing.countDocuments({ userId, laundryStatus: 'washing' });
  const currentlyDrying = await Clothing.countDocuments({ userId, laundryStatus: 'drying' });
  const readyItems = await Clothing.countDocuments({ userId, laundryStatus: 'ready' });

  const averageTimeInLaundryAgg = await LaundryHistory.aggregate([
    { $match: { userId, newStatus: 'clean' } },
    {
      $lookup: {
        from: 'laundryhistories',
        let: { clothingId: '$clothingId', changedAt: '$changedAt' },
        pipeline: [
          { $match: { $expr: { $and: [{ $eq: ['$clothingId', '$$clothingId'] }, { $lt: ['$changedAt', '$$changedAt'] }, { $eq: ['$newStatus', 'dirty'] }] } } },
          { $sort: { changedAt: -1 } },
          { $limit: 1 },
        ],
        as: 'previousDirty',
      },
    },
    { $unwind: { path: '$previousDirty', preserveNullAndEmptyArrays: true } },
    { $project: { durationMs: { $subtract: ['$changedAt', '$previousDirty.changedAt'] } } },
    { $match: { durationMs: { $gt: 0 } } },
    { $group: { _id: null, averageMs: { $avg: '$durationMs' } } },
  ]);
  const averageTimeInLaundry = averageTimeInLaundryAgg?.[0]?.averageMs ? Number((averageTimeInLaundryAgg[0].averageMs / 1000 / 60 / 60).toFixed(2)) : 0;

  const mostFrequentlyWashed = await Clothing.find({ userId, laundryCount: { $gt: 0 } }).sort({ laundryCount: -1 }).limit(5).lean();
  const laundryByCategory = await Clothing.aggregate([
    { $match: { userId, laundryStatus: { $ne: 'clean' } } },
    { $group: { _id: '$category', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);
  const laundryFrequencyByMonth = await LaundryHistory.aggregate([
    { $match: historyMatch },
    { $group: { _id: { $dateToString: { format: '%Y-%m', date: '$changedAt' } }, count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
  ]);

  return {
    totalLaundryCycles,
    currentlyDirty,
    currentlyWashing,
    currentlyDrying,
    readyItems,
    averageTimeInLaundryHours: averageTimeInLaundry,
    mostFrequentlyWashedItems: mostFrequentlyWashed.map((item) => ({ clothingId: item._id, name: item.subCategory || item.category || 'Item', laundryCount: safeNumber(item.laundryCount), image: item.imageUrl || '' })),
    laundryByCategory: laundryByCategory.map((entry) => ({ category: entry._id || 'Unknown', count: entry.count })),
    laundryFrequencyByMonth: laundryFrequencyByMonth.map((entry) => ({ period: entry._id, count: entry.count })),
  };
};

export const getCostPerWearAnalytics = async ({ userId }) => {
  const items = await Clothing.find({ userId, purchasePrice: { $gt: 0 }, wearCount: { $gt: 0 } }).lean();
  const costItems = items.map((item) => ({
    clothingId: item._id,
    name: item.subCategory || item.category || 'Item',
    image: item.imageUrl || '',
    category: item.category || 'other',
    wearCount: safeNumber(item.wearCount),
    purchasePrice: safeNumber(item.purchasePrice),
    costPerWear: Number((safeNumber(item.purchasePrice) / item.wearCount).toFixed(2)),
  }));
  const sortedAsc = [...costItems].sort((a, b) => a.costPerWear - b.costPerWear);
  const sortedDesc = [...costItems].sort((a, b) => b.costPerWear - a.costPerWear);
  const totalCost = costItems.reduce((sum, item) => sum + item.purchasePrice, 0);
  const totalWears = costItems.reduce((sum, item) => sum + item.wearCount, 0);
  const averageCostPerWear = totalWears > 0 ? Number((totalCost / totalWears).toFixed(2)) : 0;

  return {
    totalWardrobeValue: await Clothing.aggregate([
      { $match: { userId, purchasePrice: { $gt: 0 } } },
      { $group: { _id: null, totalValue: { $sum: '$purchasePrice' } } },
    ]).then((result) => result?.[0]?.totalValue ?? 0),
    averageCostPerWear,
    highestCostPerWear: sortedDesc.slice(0, 5),
    bestValueItems: sortedAsc.slice(0, 5),
  };
};

export const getSustainabilityAnalytics = async ({ userId, from, to }) => {
  const totalItems = await Clothing.countDocuments({ userId });
  const uniqueItemsWorn = (await WearHistory.distinct('clothingId', buildMatch({ userId, from, to, dateField: 'date' }))).length;
  const totalWears = await WearHistory.countDocuments(buildMatch({ userId, from, to, dateField: 'date' }));
  const averageWearsPerItem = totalItems > 0 ? Number((totalWears / totalItems).toFixed(2)) : 0;
  const utilization = totalItems > 0 ? Number(((uniqueItemsWorn / totalItems) * 100).toFixed(0)) : 0;
  const reuseScore = totalItems > 0 ? Number(((uniqueItemsWorn + averageWearsPerItem) / 2).toFixed(0)) : 0;
  const mostReused = await Clothing.find({ userId }).sort({ wearCount: -1 }).limit(5).lean();
  const leastUsed = await Clothing.find({ userId }).sort({ wearCount: 1 }).limit(5).lean();

  return {
    reuseScore,
    wardrobeUtilization: utilization,
    averageWearsPerItem,
    mostReusedClothing: mostReused.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      wearCount: safeNumber(item.wearCount),
      image: item.imageUrl || '',
    })),
    leastUsedClothing: leastUsed.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      wearCount: safeNumber(item.wearCount),
      image: item.imageUrl || '',
    })),
  };
};

export const getTrendAnalytics = async ({ userId, from, to, interval = 'monthly' }) => {
  const match = buildMatch({ userId, from, to, dateField: 'date' });
  let format = '%Y-%m';
  if (interval === 'weekly') format = '%G-%V';
  if (interval === 'yearly') format = '%Y';

  const trend = await WearHistory.aggregate([
    { $match: match },
    { $group: { _id: { $dateToString: { format, date: '$date' } }, count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
  ]);
  return {
    interval,
    data: trend.map((entry) => ({ period: entry._id, count: entry.count })),
  };
};

export const getUnusedItems = async ({ userId, page = 1, limit = 20 }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const query = { userId, $or: [{ wearCount: 0 }, { wearCount: { $exists: false } }] };
  const [items, totalItems] = await Promise.all([
    Clothing.find(query).sort({ createdAt: -1 }).skip((safePage - 1) * safeLimit).limit(safeLimit).lean(),
    Clothing.countDocuments(query),
  ]);

  return {
    items: items.map((item) => ({
      clothingId: item._id,
      name: item.subCategory || item.category || 'Item',
      image: item.imageUrl || '',
      category: item.category || 'other',
      dateAdded: item.createdAt || null,
      purchasePrice: safeNumber(item.purchasePrice),
    })),
    pagination: {
      page: safePage,
      limit: safeLimit,
      totalItems,
      totalPages: Math.max(Math.ceil(totalItems / safeLimit), 1),
      hasMore: safePage * safeLimit < totalItems,
    },
  };
};

const buildInsightMessage = ({ overview, categoryStats, colorStats, costStats, wardrobeStats }) => {
  return [
    'Do not invent any data. Use only the values provided in the JSON object.',
    'Return a valid JSON object with keys summary, insights, and recommendations.',
    'The summary should be a short paragraph about wardrobe use and habits.',
    'Each insight should include type, title, description, and priority.',
    'Recommendations should include actions with existing item IDs where applicable.',
    'If there is insufficient information, return an empty recommendations array.',
    '',
    'Input JSON:',
    JSON.stringify({ overview, categoryStats, colorStats, costStats, wardrobeStats }, null, 2),
  ].join('\n');
};

export const buildAnalyticsInsights = async ({ overview, categoryStats, colorStats, costStats, wardrobeStats }) => {
  const summary = {
    wardrobeCount: overview.wardrobeCount,
    totalWears: overview.totalWears,
    unusedItems: overview.unusedItems,
    topCategories: categoryStats.slice(0, 3).map((entry) => entry.category),
    topColors: colorStats.slice(0, 3).map((entry) => entry.color),
    averageCostPerWear: overview.averageCostPerWear,
    wardrobeUtilization: wardrobeStats.itemsByAvailability?.find((entry) => entry.label === 'Available')?.count ?? 0,
  };

  const localInsights = () => {
    const insights = [];
    if (overview.unusedItems > 0) {
      insights.push({ type: 'WARDROBE', title: 'Unused Pieces', description: `You have ${overview.unusedItems} items that have never been worn. Consider styling them into new outfits.`, priority: 'medium' });
    }
    if (overview.averageCostPerWear > 0) {
      insights.push({ type: 'COST', title: 'Cost per Wear', description: `Your average cost per wear is ${overview.averageCostPerWear}. More frequent use of existing items improves value.`, priority: 'low' });
    }
    if (wardrobeStats.wardrobeValue > 0 && overview.totalWears > 0) {
      insights.push({ type: 'SUSTAINABILITY', title: 'Wardrobe Utilization', description: `Your wardrobe utilization is around ${Number(((overview.uniqueItemsWorn / Math.max(overview.wardrobeCount, 1)) * 100).toFixed(0))}%. Try rotating more pieces to improve reuse.`, priority: 'low' });
    }
    const recommendations = overview.unusedItems > 0 ? [{ type: 'STYLE_UNUSED_ITEM', clothingId: null }] : [];
    return {
      summary: `Your wardrobe contains ${overview.wardrobeCount} items and ${overview.totalWears} recorded wears. ${overview.unusedItems} items remain unused, and your average cost per wear is ${overview.averageCostPerWear}.`,
      insights,
      recommendations,
    };
  };

  if (!process.env.GEMINI_API_KEY) {
    return localInsights();
  }

  const prompt = buildInsightMessage({ overview, categoryStats, colorStats, costStats, wardrobeStats });
  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('[ANALYTICS AI] Gemini error', { status: response.status, raw });
    return localInsights();
  }

  let data;
  try {
    data = JSON.parse(raw);
  } catch (error) {
    console.error('[ANALYTICS AI] invalid JSON', { error: error.message, raw });
    return localInsights();
  }

  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || data?.candidates?.[0]?.content?.text || '';
  if (!text) {
    console.error('[ANALYTICS AI] missing text', { raw });
    return localInsights();
  }

  try {
    const parsed = JSON.parse(text);
    if (typeof parsed !== 'object' || !parsed) return localInsights();
    return {
      summary: parsed.summary || localInsights().summary,
      insights: Array.isArray(parsed.insights) ? parsed.insights : localInsights().insights,
      recommendations: Array.isArray(parsed.recommendations) ? parsed.recommendations : localInsights().recommendations,
    };
  } catch (error) {
    console.error('[ANALYTICS AI] parse error', { error: error.message, text });
    return localInsights();
  }
};
