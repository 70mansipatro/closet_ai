import { AppError } from '../../utils/appError.js';
import { announcementCreateSchema } from '../../validators/notification.validator.js';
import * as adminNotificationService from '../../services/admin/adminNotificationService.js';
import { logAction } from '../../services/admin/adminAuditService.js';

export const getNotifications = async (req, res, next) => {
  try {
    const { page, limit, type, userId, status } = req.query;
    const data = await adminNotificationService.listNotifications({
      page: Number(page) || 1,
      limit: Number(limit) || 20,
      type: type?.toString(),
      userId: userId?.toString(),
      status: status?.toString(),
    });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getNotificationStats = async (req, res, next) => {
  try {
    const data = await adminNotificationService.getNotificationStats();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createAnnouncement = async (req, res, next) => {
  try {
    const { error, value } = announcementCreateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const announcement = await adminNotificationService.createAnnouncement({ payload: value, createdBy: req.user._id });

    await logAction({
      adminUserId: req.user._id,
      action: 'ANNOUNCEMENT_CREATED',
      targetType: 'Announcement',
      targetId: announcement._id,
      description: `Created announcement "${announcement.title}" for audience ${announcement.targetAudience}`,
      req,
    });

    res.status(201).json({ success: true, data: announcement, message: 'Announcement scheduled' });
  } catch (error) {
    next(error);
  }
};

export const listAnnouncements = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const data = await adminNotificationService.listAnnouncements({ page: Number(page) || 1, limit: Number(limit) || 20 });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const cancelAnnouncement = async (req, res, next) => {
  try {
    const announcement = await adminNotificationService.cancelAnnouncement({ id: req.params.id });

    await logAction({
      adminUserId: req.user._id,
      action: 'ANNOUNCEMENT_CANCELLED',
      targetType: 'Announcement',
      targetId: req.params.id,
      description: `Cancelled announcement "${announcement.title}"`,
      req,
    });

    res.status(200).json({ success: true, data: announcement, message: 'Announcement cancelled' });
  } catch (error) {
    next(error);
  }
};

export const getReminders = async (req, res, next) => {
  try {
    const { page, limit, type, enabled } = req.query;
    const data = await adminNotificationService.listReminders({
      page: Number(page) || 1,
      limit: Number(limit) || 20,
      type: type?.toString(),
      enabled: enabled === undefined ? undefined : enabled === 'true',
    });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getReminderStats = async (req, res, next) => {
  try {
    const data = await adminNotificationService.getReminderStats();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
