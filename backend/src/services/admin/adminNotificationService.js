import { AppError } from '../../utils/appError.js';
import Notification from '../../models/Notification.js';
import Reminder from '../../models/Reminder.js';
import Announcement from '../../models/Announcement.js';

export const listNotifications = async ({ page = 1, limit = 20, type, userId, status }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const match = {};
  if (type) match.type = type;
  if (userId) match.userId = userId;
  if (status) match.status = status;

  const [items, total] = await Promise.all([
    Notification.find(match)
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate('userId', 'name email')
      .lean(),
    Notification.countDocuments(match),
  ]);

  return {
    items,
    page: safePage,
    limit: safeLimit,
    total,
    totalPages: Math.max(Math.ceil(total / safeLimit), 1),
  };
};

export const getNotificationStats = async () => {
  const [totals, byType, byDay] = await Promise.all([
    Notification.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          read: { $sum: { $cond: ['$isRead', 1, 0] } },
          unread: { $sum: { $cond: ['$isRead', 0, 1] } },
          cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
          failed: { $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] } },
          expired: { $sum: { $cond: [{ $eq: ['$status', 'expired'] }, 1, 0] } },
        },
      },
    ]),
    Notification.aggregate([{ $group: { _id: '$type', count: { $sum: 1 } } }, { $sort: { count: -1 } }]),
    Notification.aggregate([
      { $match: { createdAt: { $gte: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000) } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]),
  ]);

  const summary = totals[0] || { total: 0, read: 0, unread: 0, cancelled: 0, failed: 0, expired: 0 };
  const readRate = summary.total > 0 ? Number(((summary.read / summary.total) * 100).toFixed(1)) : 0;

  return {
    total: summary.total,
    read: summary.read,
    unread: summary.unread,
    readRate,
    cancelled: summary.cancelled,
    failed: summary.failed,
    expired: summary.expired,
    byType: byType.map((entry) => ({ type: entry._id, count: entry.count })),
    byDay: byDay.map((entry) => ({ date: entry._id, count: entry.count })),
  };
};

export const createAnnouncement = async ({ payload, createdBy }) => {
  if (payload.targetAudience === 'specificUsers' && !payload.targetUserIds?.length) {
    throw new AppError('targetUserIds is required for specificUsers audience', 400);
  }
  return Announcement.create({ ...payload, createdBy });
};

export const cancelAnnouncement = async ({ id }) => {
  const announcement = await Announcement.findOneAndUpdate(
    { _id: id, status: 'scheduled' },
    { status: 'cancelled' },
    { new: true }
  );
  if (!announcement) throw new AppError('Scheduled announcement not found', 404);
  return announcement;
};

export const listAnnouncements = async ({ page = 1, limit = 20 }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const [items, total] = await Promise.all([
    Announcement.find({})
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .lean(),
    Announcement.countDocuments({}),
  ]);

  return { items, page: safePage, limit: safeLimit, total, totalPages: Math.max(Math.ceil(total / safeLimit), 1) };
};

export const listReminders = async ({ page = 1, limit = 20, type, enabled }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const match = {};
  if (type) match.type = type;
  if (enabled !== undefined) match.enabled = enabled;

  const [items, total] = await Promise.all([
    Reminder.find(match)
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate('userId', 'name email')
      .lean(),
    Reminder.countDocuments(match),
  ]);

  return { items, page: safePage, limit: safeLimit, total, totalPages: Math.max(Math.ceil(total / safeLimit), 1) };
};

export const getReminderStats = async () => {
  const [totals, byType] = await Promise.all([
    Reminder.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          enabled: { $sum: { $cond: ['$enabled', 1, 0] } },
          disabled: { $sum: { $cond: ['$enabled', 0, 1] } },
          smart: { $sum: { $cond: [{ $eq: ['$frequency', 'smart'] }, 1, 0] } },
        },
      },
    ]),
    Reminder.aggregate([{ $group: { _id: '$type', count: { $sum: 1 } } }, { $sort: { count: -1 } }]),
  ]);

  const summary = totals[0] || { total: 0, enabled: 0, disabled: 0, smart: 0 };
  return { ...summary, byType: byType.map((entry) => ({ type: entry._id, count: entry.count })) };
};
