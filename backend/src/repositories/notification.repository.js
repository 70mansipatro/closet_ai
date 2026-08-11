import Notification from '../models/Notification.js';

const buildListQuery = ({ userId, unreadOnly, type, startDate, endDate }) => {
  const query = { userId };
  if (unreadOnly) query.isRead = false;
  if (type) query.type = type;
  if (startDate && endDate) query.createdAt = { $gte: startDate, $lte: endDate };
  return query;
};

export const findForUser = async ({
  userId,
  page = 1,
  limit = 20,
  unreadOnly = false,
  type,
  startDate,
  endDate,
}) => {
  const query = buildListQuery({ userId, unreadOnly, type, startDate, endDate });
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;

  const [items, totalItems] = await Promise.all([
    Notification.find(query).sort({ createdAt: -1 }).skip(skip).limit(safeLimit).lean(),
    Notification.countDocuments(query),
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

export const countUnread = async ({ userId }) => Notification.countDocuments({ userId, isRead: false });

export const findById = async ({ userId, id }) => Notification.findOne({ _id: id, userId });

export const markRead = async ({ userId, id }) =>
  Notification.findOneAndUpdate(
    { _id: id, userId },
    { isRead: true, readAt: new Date(), status: 'read' },
    { new: true }
  );

export const markAllRead = async ({ userId }) =>
  Notification.updateMany({ userId, isRead: false }, { isRead: true, readAt: new Date(), status: 'read' });

export const deleteOne = async ({ userId, id }) => Notification.findOneAndDelete({ _id: id, userId });

export const deleteAllForUser = async ({ userId }) => Notification.deleteMany({ userId });

export const createOne = async (payload) => Notification.create(payload);

export const createMany = async (payloads) => {
  if (!payloads.length) return [];
  return Notification.insertMany(payloads, { ordered: false });
};

export const existsDuplicate = async ({ userId, type, sourceId, sourceType, since }) => {
  const query = { userId, type, createdAt: { $gte: since } };
  if (sourceId) query.sourceId = sourceId;
  if (sourceType) query.sourceType = sourceType;
  const existing = await Notification.findOne(query).lean();
  return Boolean(existing);
};

export const countTodayForUser = async ({ userId, since }) =>
  Notification.countDocuments({ userId, createdAt: { $gte: since } });

export const findLastForUser = async ({ userId }) =>
  Notification.findOne({ userId }).sort({ createdAt: -1 }).lean();

export const cleanupExpired = async ({ retentionDays = 90 }) => {
  const cutoff = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);
  const result = await Notification.deleteMany({
    createdAt: { $lte: cutoff },
    status: { $in: ['read', 'expired', 'cancelled', 'sent'] },
  });
  return result.deletedCount || 0;
};

export const markExpired = async () =>
  Notification.updateMany(
    { expiresAt: { $ne: null, $lte: new Date() }, status: { $nin: ['expired', 'cancelled'] } },
    { status: 'expired' }
  );
