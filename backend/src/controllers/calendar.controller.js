import { AppError } from '../utils/appError.js';
import {
  scheduleOutfitForDate,
  wearToday as wearTodayService,
} from '../services/calendar.service.js';
import {
  createCalendarEntry,
  findCalendarForUser,
  findCalendarByDate,
  findCalendarById,
  updateCalendarEntry as updateCalendarRepo,
  deleteCalendarEntry,
} from '../repositories/calendar.repository.js';
import { scheduleSchema } from '../validators/calendar.validator.js';

export const schedule = async (req, res, next) => {
  try {
    const payload = { ...(req.body || {}) };
    payload.userId = req.user._id;
    const { error, value } = scheduleSchema.validate(payload);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await scheduleOutfitForDate({ userId: req.user._id, payload: value });
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const list = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    const entries = await findCalendarForUser({ userId: req.user._id, startDate: startDate ? new Date(startDate) : null, endDate: endDate ? new Date(endDate) : null });
    res.status(200).json({ success: true, data: entries });
  } catch (error) {
    next(error);
  }
};

export const getByDate = async (req, res, next) => {
  try {
    const date = new Date(req.params.date);
    if (Number.isNaN(date.getTime())) throw new AppError('Invalid date format', 400);
    const entry = await findCalendarByDate({ userId: req.user._id, date });
    res.status(200).json({ success: true, data: entry });
  } catch (error) {
    next(error);
  }
};

export const update = async (req, res, next) => {
  try {
    const id = req.params.id;
    const updateData = req.body || {};
    const updated = await updateCalendarRepo({ userId: req.user._id, id, updateData });
    if (!updated) throw new AppError('Calendar entry not found', 404);
    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
};

export const remove = async (req, res, next) => {
  try {
    const id = req.params.id;
    const removed = await deleteCalendarEntry({ userId: req.user._id, id });
    if (!removed) throw new AppError('Calendar entry not found', 404);
    res.status(200).json({ success: true, message: 'Calendar entry deleted' });
  } catch (error) {
    next(error);
  }
};

export const wearToday = async (req, res, next) => {
  try {
    const { outfitId } = req.body || {};
    const result = await wearTodayService({ userId: req.user._id, outfitId });
    if (result.alreadyWorn) return res.status(200).json({ success: true, message: result.message });
    res.status(200).json({ success: true, data: { createdCount: result.createdCount } });
  } catch (error) {
    next(error);
  }
};
