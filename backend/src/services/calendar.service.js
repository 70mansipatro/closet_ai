import { AppError } from '../utils/appError.js';
import { findOutfitById } from '../repositories/outfit.repository.js';
import { findClothingById, updateClothingItem } from '../repositories/clothing.repository.js';
import { createWearHistory, findUserOutfitHistoryOnDate } from '../repositories/history.repository.js';
import { createCalendarEntry, findCalendarByDate, updateCalendarEntry } from '../repositories/calendar.repository.js';
import Clothing from '../models/Clothing.js';

const startOfDay = (d) => {
  const t = new Date(d);
  t.setUTCHours(0, 0, 0, 0);
  return t;
};

export const scheduleOutfitForDate = async ({ userId, payload }) => {
  const date = startOfDay(payload.date || new Date());
  const existing = await findCalendarByDate({ userId, date });
  if (existing) {
    Object.assign(existing, payload);
    return existing.save();
  }

  const savePayload = { ...payload, userId, date };
  return createCalendarEntry({ payload: savePayload });
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

  // update clothing wearCount and lastWorn
  if (clothingIds.length > 0) {
    await Clothing.updateMany({ _id: { $in: clothingIds }, userId }, { $set: { lastWorn: now }, $inc: { wearCount: 1 } });
  }

  // create wear history entries for each clothing id
  const created = [];
  for (const clothingId of clothingIds) {
    // prevent duplicate for clothing+outfit+date
    const exists = await createWearHistory({ payload: { userId, clothingId, outfitId, date: today, occasion: outfit?.occasion || '', weather: outfit?.weather || '', notes: '' } });
    created.push(exists);
  }

  // mark calendar entry for today as Worn
  const calendarEntry = await findCalendarByDate({ userId, date: today });
  if (calendarEntry) {
    calendarEntry.status = 'Worn';
    calendarEntry.outfitId = outfitId || calendarEntry.outfitId;
    calendarEntry.updatedAt = new Date();
    await calendarEntry.save();
  } else {
    await createCalendarEntry({ payload: { userId, date: today, outfitId: outfitId || null, status: 'Worn' } });
  }

  return { alreadyWorn: false, createdCount: created.length };
};
