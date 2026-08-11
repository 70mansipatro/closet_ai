import { AppError } from '../utils/appError.js';
import {
  notificationListQuerySchema,
  preferencesUpdateSchema,
  smartSettingsUpdateSchema,
} from '../validators/notification.validator.js';
import {
  listNotifications,
  getUnreadCount,
  getNotificationById,
  markNotificationRead,
  markAllNotificationsRead,
  deleteNotification,
  deleteAllNotifications,
  getPreferences,
  updatePreferences,
  getSmartSettings,
  updateSmartSettings,
} from '../services/notification.service.js';

export const listNotificationsHandler = async (req, res, next) => {
  try {
    const { error, value } = notificationListQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await listNotifications({ userId: req.user._id, ...value });
    res.status(200).json({ success: true, data: result.items, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const unreadCountHandler = async (req, res, next) => {
  try {
    const count = await getUnreadCount({ userId: req.user._id });
    res.status(200).json({ success: true, data: { count } });
  } catch (error) {
    next(error);
  }
};

export const getNotificationHandler = async (req, res, next) => {
  try {
    const notification = await getNotificationById({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, data: notification });
  } catch (error) {
    next(error);
  }
};

export const markReadHandler = async (req, res, next) => {
  try {
    const notification = await markNotificationRead({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, data: notification });
  } catch (error) {
    next(error);
  }
};

export const markAllReadHandler = async (req, res, next) => {
  try {
    const result = await markAllNotificationsRead({ userId: req.user._id });
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const deleteNotificationHandler = async (req, res, next) => {
  try {
    await deleteNotification({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    next(error);
  }
};

export const deleteAllNotificationsHandler = async (req, res, next) => {
  try {
    const result = await deleteAllNotifications({ userId: req.user._id });
    res.status(200).json({ success: true, data: result, message: 'All notifications deleted' });
  } catch (error) {
    next(error);
  }
};

export const getPreferencesHandler = async (req, res, next) => {
  try {
    const preferences = await getPreferences({ userId: req.user._id });
    res.status(200).json({ success: true, data: preferences });
  } catch (error) {
    next(error);
  }
};

export const updatePreferencesHandler = async (req, res, next) => {
  try {
    const { error, value } = preferencesUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const preferences = await updatePreferences({ userId: req.user._id, updateData: value });
    res.status(200).json({ success: true, data: preferences });
  } catch (error) {
    next(error);
  }
};

export const getSmartSettingsHandler = async (req, res, next) => {
  try {
    const settings = await getSmartSettings({ userId: req.user._id });
    res.status(200).json({ success: true, data: settings });
  } catch (error) {
    next(error);
  }
};

export const updateSmartSettingsHandler = async (req, res, next) => {
  try {
    const { error, value } = smartSettingsUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const settings = await updateSmartSettings({ userId: req.user._id, updateData: value });
    res.status(200).json({ success: true, data: settings });
  } catch (error) {
    next(error);
  }
};
