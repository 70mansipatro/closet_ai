import { AppError } from '../utils/appError.js';
import {
  reminderCreateSchema,
  reminderUpdateSchema,
  reminderSnoozeSchema,
} from '../validators/notification.validator.js';
import {
  listReminders,
  getReminder,
  createUserReminder,
  updateUserReminder,
  deleteUserReminder,
  toggleUserReminder,
  snoozeUserReminder,
} from '../services/reminder.service.js';

export const listRemindersHandler = async (req, res, next) => {
  try {
    const { type, enabled } = req.query;
    const reminders = await listReminders({
      userId: req.user._id,
      type: type?.toString(),
      enabled: enabled === undefined ? undefined : enabled === 'true',
    });
    res.status(200).json({ success: true, data: reminders });
  } catch (error) {
    next(error);
  }
};

export const getReminderHandler = async (req, res, next) => {
  try {
    const reminder = await getReminder({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, data: reminder });
  } catch (error) {
    next(error);
  }
};

export const createReminderHandler = async (req, res, next) => {
  try {
    const { error, value } = reminderCreateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const reminder = await createUserReminder({ userId: req.user._id, payload: value });
    res.status(201).json({ success: true, data: reminder });
  } catch (error) {
    next(error);
  }
};

export const updateReminderHandler = async (req, res, next) => {
  try {
    const { error, value } = reminderUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const reminder = await updateUserReminder({ userId: req.user._id, id: req.params.id, updateData: value });
    res.status(200).json({ success: true, data: reminder });
  } catch (error) {
    next(error);
  }
};

export const deleteReminderHandler = async (req, res, next) => {
  try {
    await deleteUserReminder({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, message: 'Reminder deleted' });
  } catch (error) {
    next(error);
  }
};

export const toggleReminderHandler = async (req, res, next) => {
  try {
    const reminder = await toggleUserReminder({ userId: req.user._id, id: req.params.id });
    res.status(200).json({ success: true, data: reminder });
  } catch (error) {
    next(error);
  }
};

export const snoozeReminderHandler = async (req, res, next) => {
  try {
    const { error, value } = reminderSnoozeSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const reminder = await snoozeUserReminder({ userId: req.user._id, id: req.params.id, ...value });
    res.status(200).json({ success: true, data: reminder });
  } catch (error) {
    next(error);
  }
};
