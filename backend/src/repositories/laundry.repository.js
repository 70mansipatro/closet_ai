import LaundryHistory from '../models/LaundryHistory.js';

export const createLaundryHistory = async ({ payload, session = null }) =>
  LaundryHistory.create([payload], { session }).then((docs) => docs[0]);

export const findLaundryHistoryForUser = async ({
  userId,
  page = 1,
  limit = 20,
  clothingId,
  newStatus,
  startDate,
  endDate,
  search,
  sortBy = 'changedAt',
  sortOrder = 'desc',
}) => {
  const query = { userId };
  if (clothingId) query.clothingId = clothingId;
  if (newStatus) query.newStatus = newStatus;
  if (startDate && endDate) query.changedAt = { $gte: startDate, $lte: endDate };
  if (search) {
    query.$or = [
      { method: { $regex: search, $options: 'i' } },
      { notes: { $regex: search, $options: 'i' } },
      { previousStatus: { $regex: search, $options: 'i' } },
      { newStatus: { $regex: search, $options: 'i' } },
    ];
  }

  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;
  const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

  const [items, totalItems] = await Promise.all([
    LaundryHistory.find(query).sort(sort).skip(skip).limit(safeLimit).lean(),
    LaundryHistory.countDocuments(query),
  ]);

  const totalPages = Math.max(Math.ceil(totalItems / safeLimit), 1);

  return {
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      totalItems,
      totalPages,
      hasMore: safePage < totalPages,
    },
  };
};

export const findLaundryHistoryByClothing = async ({ userId, clothingId }) =>
  LaundryHistory.find({ userId, clothingId }).sort({ changedAt: -1 }).lean();

export const findRecentLaundryHistory = async ({
  userId,
  clothingId,
  newStatus,
  method,
  withinSeconds = 30,
}) => {
  const since = new Date(Date.now() - withinSeconds * 1000);
  const query = {
    userId,
    clothingId,
    newStatus,
    method,
    changedAt: { $gte: since },
  };
  return LaundryHistory.findOne(query).lean();
};
