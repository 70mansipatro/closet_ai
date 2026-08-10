import WearHistory from '../models/WearHistory.js';

export const createWearHistory = async ({ payload }) => WearHistory.create(payload);

export const findWearHistoryForUser = async ({ userId, page = 1, limit = 20, search, clothingId, outfitId, startDate, endDate }) => {
  const query = { userId };
  if (clothingId) query.clothingId = clothingId;
  if (outfitId) query.outfitId = outfitId;
  if (startDate && endDate) query.date = { $gte: startDate, $lte: endDate };
  if (search) query.$or = [{ notes: { $regex: search, $options: 'i' } }, { occasion: { $regex: search, $options: 'i' } }];

  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;

  const [items, totalItems] = await Promise.all([
    WearHistory.find(query).sort({ date: -1 }).skip(skip).limit(safeLimit),
    WearHistory.countDocuments(query),
  ]);

  const totalPages = Math.max(Math.ceil(totalItems / safeLimit), 1);
  return {
    items,
    pagination: { page: safePage, limit: safeLimit, totalItems, totalPages, hasMore: safePage < totalPages },
  };
};

export const findWearHistoryByClothing = async ({ userId, clothingId }) => WearHistory.find({ userId, clothingId }).sort({ date: -1 });

export const findWearHistoryByOutfit = async ({ userId, outfitId }) => WearHistory.find({ userId, outfitId }).sort({ date: -1 });

export const findUserOutfitHistoryOnDate = async ({ userId, outfitId, date }) =>
  WearHistory.findOne({ userId, outfitId, date });
