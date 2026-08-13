import { AppError } from '../utils/appError.js';
import { findOutfitById } from '../repositories/outfit.repository.js';
import { findUserOutfitHistoryOnDate } from '../repositories/history.repository.js';
import { createCalendarEntry, findCalendarByDate, updateCalendarEntry } from '../repositories/calendar.repository.js';
import Clothing from '../models/Clothing.js';
import { syncOutfitReminder, cancelOutfitReminder } from './reminder.service.js';
import { markManyClothingWorn } from './wear.service.js';

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

const startOfDay = (d) => {
  const t = new Date(d);
  t.setUTCHours(0, 0, 0, 0);
  return t;
};

export const scheduleOutfitForDate = async ({ userId, payload }) => {
  const date = startOfDay(payload.date || new Date());
  const existing = await findCalendarByDate({ userId, date });

  let result;
  if (existing) {
    Object.assign(existing, payload);
    result = await existing.save();
  } else {
    const savePayload = { ...payload, userId, date };
    result = await createCalendarEntry({ payload: savePayload });
  }

  await syncOutfitReminderSafely({ userId, calendarEntry: result });
  return result;
};

export const wearToday = async ({ userId, outfitId }) => {
  if (!userId) throw new AppError('userId required', 400);

  const today = startOfDay(new Date());
  // prevent duplicate outfit wear history for same outfit and day
  const existingHistory = outfitId ? await findUserOutfitHistoryOnDate({ userId, outfitId, date: today }) : null;
  if (existingHistory) {
    return { alreadyWorn: true, message: 'This outfit has already been marked as worn today.' };
  }

  const outfit = outfitId ? await findOutfitById({ userId, id: outfitId }) : null;

  // Determine clothing ids to update
  const clothingIds = [];
  if (outfit && Array.isArray(outfit.recommendedItems)) {
    for (const it of outfit.recommendedItems) {
      if (it && it._id) clothingIds.push(it._id);
    }
  } else if (outfit) {
    // fallback to named fields
    for (const field of ['top', 'bottom', 'footwear', 'outerwear']) {
      if (outfit[field]) {
        // try to find clothing item by name
        const found = await Clothing.findOne({ userId, name: outfit[field] }).lean();
        if (found) clothingIds.push(found._id);
      }
    }
  }

  const now = new Date();

  // Atomically bump wearCount/lastWorn, flip laundryStatus clean->dirty, and
  // write a WearHistory row per item — the same transaction Wardrobe's
  // "Mark as Worn" and AI's "Wear This Outfit" use, so Analytics stays
  // consistent regardless of which entry point wore the outfit.
  const created = await markManyClothingWorn({
    userId,
    clothingIds,
    outfitId,
    occasion: outfit?.occasion || '',
    weather: outfit?.weather || '',
    wornAt: now,
  });

  // mark calendar entry for today as Worn
  const calendarEntry = await findCalendarByDate({ userId, date: today });
  let wornEntryId;
  if (calendarEntry) {
    calendarEntry.status = 'Worn';
    calendarEntry.outfitId = outfitId || calendarEntry.outfitId;
    calendarEntry.updatedAt = new Date();
    await calendarEntry.save();
    wornEntryId = calendarEntry._id;
  } else {
    const newEntry = await createCalendarEntry({ payload: { userId, date: today, outfitId: outfitId || null, status: 'Worn' } });
    wornEntryId = newEntry._id;
  }
  await cancelOutfitReminderSafely({ userId, calendarEntryId: wornEntryId });

  return { alreadyWorn: false, createdCount: created.length };
};
