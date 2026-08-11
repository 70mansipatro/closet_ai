import { AppError } from '../utils/appError.js';
import NotificationPreference from '../models/NotificationPreference.js';
import SmartReminderSetting from '../models/SmartReminderSetting.js';
import {
  findForUser,
  countUnread,
  findById,
  markRead,
  markAllRead,
  deleteOne,
  deleteAllForUser,
} from '../repositories/notification.repository.js';

export const listNotifications = async ({ userId, page, limit, unreadOnly, type, startDate, endDate }) =>
  findForUser({ userId, page, limit, unreadOnly, type, startDate, endDate });

export const getUnreadCount = async ({ userId }) => countUnread({ userId });

export const getNotificationById = async ({ userId, id }) => {
  const notification = await findById({ userId, id });
  if (!notification) throw new AppError('Notification not found', 404);
  return notification;
};

export const markNotificationRead = async ({ userId, id }) => {
  const notification = await markRead({ userId, id });
  if (!notification) throw new AppError('Notification not found', 404);
  return notification;
};

export const markAllNotificationsRead = async ({ userId }) => {
  const result = await markAllRead({ userId });
  return { modifiedCount: result.modifiedCount || 0 };
};

export const deleteNotification = async ({ userId, id }) => {
  const notification = await deleteOne({ userId, id });
  if (!notification) throw new AppError('Notification not found', 404);
  return notification;
};

export const deleteAllNotifications = async ({ userId }) => {
  const result = await deleteAllForUser({ userId });
  return { deletedCount: result.deletedCount || 0 };
};

export const getPreferences = async ({ userId }) => {
  let preferences = await NotificationPreference.findOne({ userId });
  if (!preferences) {
    preferences = await NotificationPreference.create({ userId });
  }
  return preferences;
};

export const updatePreferences = async ({ userId, updateData }) => {
  const preferences = await NotificationPreference.findOneAndUpdate(
    { userId },
    { $set: updateData },
    { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
  );
  return preferences;
};

export const getSmartSettings = async ({ userId }) => {
  let settings = await SmartReminderSetting.findOne({ userId });
  if (!settings) {
    settings = await SmartReminderSetting.create({ userId });
  }
  return settings;
};

export const updateSmartSettings = async ({ userId, updateData }) => {
  const settings = await SmartReminderSetting.findOneAndUpdate(
    { userId },
    { $set: updateData },
    { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
  );
  return settings;
};

const toMinutes = (hhmm) => {
  const [h, m] = (hhmm || '00:00').split(':').map((v) => Number(v) || 0);
  return h * 60 + m;
};

export const isWithinQuietHours = (preferences, now = new Date()) => {
  if (!preferences?.quietHoursEnabled) return false;
  const nowMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  const start = toMinutes(preferences.quietHoursStart);
  const end = toMinutes(preferences.quietHoursEnd);
  if (start === end) return false;
  if (start < end) {
    return nowMinutes >= start && nowMinutes < end;
  }
  return nowMinutes >= start || nowMinutes < end;
};
