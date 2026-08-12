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
import { syncOutfitReminder, cancelOutfitReminder } from '../services/reminder.service.js';
import Clothing from '../models/Clothing.js';
import Outfit from '../models/Outfit.js';

// Attaches read-only, human-friendly fields (topItem/bottomItem/.../outfit) to
// calendar entries for API responses, without touching topId/outfitId etc. —
// those raw refs must stay untouched since calendar.service.js re-saves the
// same Mongoose documents returned by findCalendarByDate/findCalendarForUser.
const attachOutfitDetails = async (entries) => {
  const list = Array.isArray(entries) ? entries : [entries].filter(Boolean);
  if (list.length === 0) return entries;

  const clothingIds = new Set();
  const outfitIds = new Set();
  list.forEach((entry) => {
    ['topId', 'bottomId', 'footwearId', 'outerwearId'].forEach((field) => {
      if (entry[field]) clothingIds.add(String(entry[field]));
    });
    (entry.accessories || []).forEach((id) => id && clothingIds.add(String(id)));
    if (entry.outfitId) outfitIds.add(String(entry.outfitId));
  });

  const [clothingDocs, outfitDocs] = await Promise.all([
    clothingIds.size
      ? Clothing.find({ _id: { $in: [...clothingIds] } })
          .select('category subCategory color imageUrl brand')
          .lean()
      : [],
    outfitIds.size
      ? Outfit.find({ _id: { $in: [...outfitIds] } })
          .select('top bottom footwear outerwear accessories occasion weather temperature')
          .lean()
      : [],
  ]);

  const clothingMap = new Map(clothingDocs.map((doc) => [String(doc._id), doc]));
  const outfitMap = new Map(outfitDocs.map((doc) => [String(doc._id), doc]));

  list.forEach((entry) => {
    entry.topItem = entry.topId ? clothingMap.get(String(entry.topId)) || null : null;
    entry.bottomItem = entry.bottomId ? clothingMap.get(String(entry.bottomId)) || null : null;
    entry.footwearItem = entry.footwearId ? clothingMap.get(String(entry.footwearId)) || null : null;
    entry.outerwearItem = entry.outerwearId ? clothingMap.get(String(entry.outerwearId)) || null : null;
    entry.accessoryItems = (entry.accessories || [])
      .map((id) => clothingMap.get(String(id)))
      .filter(Boolean);
    entry.outfit = entry.outfitId ? outfitMap.get(String(entry.outfitId)) || null : null;
  });

  return entries;
};

const syncOutfitReminderSafely = async ({ userId, calendarEntry }) => {
  try {
    await syncOutfitReminder({ userId, calendarEntry });
  } catch (error) {
    console.error('[REMINDER HOOK] failed to sync outfit reminder', { userId, error: error.message });
  }
};

const cancelOutfitReminderSafely = async ({ userId, calendarEntryId }) => {
  try {
    await cancelOutfitReminder({ userId, calendarEntryId });
  } catch (error) {
    console.error('[REMINDER HOOK] failed to cancel outfit reminder', { userId, error: error.message });
  }
};

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
    const enriched = await attachOutfitDetails(entries.map((entry) => entry.toObject()));
    res.status(200).json({ success: true, data: enriched });
  } catch (error) {
    next(error);
  }
};

export const getByDate = async (req, res, next) => {
  try {
    const date = new Date(req.params.date);
    if (Number.isNaN(date.getTime())) throw new AppError('Invalid date format', 400);
    const entry = await findCalendarByDate({ userId: req.user._id, date });
    const enriched = entry ? (await attachOutfitDetails([entry.toObject()]))[0] : null;
    res.status(200).json({ success: true, data: enriched });
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
    await syncOutfitReminderSafely({ userId: req.user._id, calendarEntry: updated });
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
    await cancelOutfitReminderSafely({ userId: req.user._id, calendarEntryId: id });
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
