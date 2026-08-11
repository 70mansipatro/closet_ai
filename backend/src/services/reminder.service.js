import { AppError } from '../utils/appError.js';
import {
  createReminder as createReminderRepo,
  findRemindersForUser,
  findReminderById,
  updateReminder as updateReminderRepo,
  deleteReminder as deleteReminderRepo,
  deleteBySource,
  upsertBySource,
} from '../repositories/reminder.repository.js';

const DAY_MS = 24 * 60 * 60 * 1000;

const applyTimeOfDay = (date, scheduledTime) => {
  const result = new Date(date);
  if (scheduledTime && /^\d{1,2}:\d{2}$/.test(scheduledTime)) {
    const [hours, minutes] = scheduledTime.split(':').map(Number);
    result.setUTCHours(hours, minutes, 0, 0);
  }
  return result;
};

const nextWeekdayOnOrAfter = (from, daysOfWeek) => {
  if (!daysOfWeek?.length) return from;
  for (let i = 0; i < 7; i += 1) {
    const candidate = new Date(from.getTime() + i * DAY_MS);
    if (daysOfWeek.includes(candidate.getUTCDay())) return candidate;
  }
  return from;
};

export const computeNextTriggerAt = (reminder, from = new Date()) => {
  const { frequency, scheduledTime, date, daysOfWeek, startDate, endDate } = reminder;

  if (frequency === 'smart') return null;

  if (frequency === 'once') {
    const base = date ? new Date(date) : from;
    return applyTimeOfDay(base, scheduledTime);
  }

  if (frequency === 'daily') {
    let candidate = applyTimeOfDay(from, scheduledTime);
    if (candidate <= from) candidate = new Date(candidate.getTime() + DAY_MS);
    if (startDate && candidate < new Date(startDate)) candidate = applyTimeOfDay(new Date(startDate), scheduledTime);
    if (endDate && candidate > new Date(endDate)) return null;
    return candidate;
  }

  if (frequency === 'weekly') {
    let candidate = applyTimeOfDay(from, scheduledTime);
    if (candidate <= from) candidate = new Date(candidate.getTime() + DAY_MS);
    candidate = nextWeekdayOnOrAfter(candidate, daysOfWeek?.length ? daysOfWeek : [candidate.getUTCDay()]);
    if (endDate && candidate > new Date(endDate)) return null;
    return candidate;
  }

  if (frequency === 'monthly') {
    const base = applyTimeOfDay(from, scheduledTime);
    const candidate = new Date(base);
    candidate.setUTCMonth(candidate.getUTCMonth() + (base <= from ? 1 : 0));
    if (endDate && candidate > new Date(endDate)) return null;
    return candidate;
  }

  return null;
};

export const listReminders = async ({ userId, type, enabled }) => findRemindersForUser({ userId, type, enabled });

export const getReminder = async ({ userId, id }) => {
  const reminder = await findReminderById({ userId, id });
  if (!reminder) throw new AppError('Reminder not found', 404);
  return reminder;
};

export const createUserReminder = async ({ userId, payload }) => {
  const nextTriggerAt = payload.frequency === 'smart' ? null : computeNextTriggerAt(payload);
  return createReminderRepo({ ...payload, userId, type: payload.type || 'CUSTOM', nextTriggerAt });
};

export const updateUserReminder = async ({ userId, id, updateData }) => {
  const existing = await findReminderById({ userId, id });
  if (!existing) throw new AppError('Reminder not found', 404);

  const merged = { ...existing.toObject(), ...updateData };
  const nextTriggerAt = merged.enabled === false ? existing.nextTriggerAt : computeNextTriggerAt(merged);

  const updated = await updateReminderRepo({ userId, id, updateData: { ...updateData, nextTriggerAt } });
  if (!updated) throw new AppError('Reminder not found', 404);
  return updated;
};

export const deleteUserReminder = async ({ userId, id }) => {
  const deleted = await deleteReminderRepo({ userId, id });
  if (!deleted) throw new AppError('Reminder not found', 404);
  return deleted;
};

export const toggleUserReminder = async ({ userId, id }) => {
  const reminder = await findReminderById({ userId, id });
  if (!reminder) throw new AppError('Reminder not found', 404);

  const enabled = !reminder.enabled;
  const nextTriggerAt = enabled ? computeNextTriggerAt(reminder.toObject()) : reminder.nextTriggerAt;

  return updateReminderRepo({ userId, id, updateData: { enabled, nextTriggerAt } });
};

const SNOOZE_PRESETS = {
  '15m': 15,
  '30m': 30,
  '1h': 60,
  tomorrow: 24 * 60,
};

export const snoozeUserReminder = async ({ userId, id, preset, minutes }) => {
  const reminder = await findReminderById({ userId, id });
  if (!reminder) throw new AppError('Reminder not found', 404);

  const snoozeMinutes = minutes ?? SNOOZE_PRESETS[preset];
  if (!snoozeMinutes || snoozeMinutes <= 0) {
    throw new AppError('Invalid snooze duration', 400);
  }

  const nextTriggerAt = new Date(Date.now() + snoozeMinutes * 60 * 1000);
  return updateReminderRepo({ userId, id, updateData: { nextTriggerAt, snoozeMinutes, enabled: true } });
};

export const markReminderTriggered = async ({ reminder, now = new Date() }) => {
  const nextTriggerAt = reminder.frequency === 'once' ? null : computeNextTriggerAt(reminder, now);
  const enabled = reminder.frequency === 'once' ? false : reminder.enabled;
  return updateReminderRepo({
    userId: reminder.userId,
    id: reminder._id,
    updateData: { lastTriggeredAt: now, nextTriggerAt, enabled },
  });
};

// ---- Integration hooks: Calendar / Laundry / Trip / Packing ----

const OUTFIT_REMINDER_HOUR_UTC = 20; // default: evening before the planned date

export const syncOutfitReminder = async ({ userId, calendarEntry }) => {
  if (!calendarEntry?.date || calendarEntry.status !== 'Planned') {
    return cancelOutfitReminder({ userId, calendarEntryId: calendarEntry?._id });
  }

  const triggerAt = new Date(calendarEntry.date);
  triggerAt.setUTCDate(triggerAt.getUTCDate() - 1);
  triggerAt.setUTCHours(OUTFIT_REMINDER_HOUR_UTC, 0, 0, 0);

  return upsertBySource({
    userId,
    sourceType: 'outfit_calendar',
    sourceId: calendarEntry._id,
    payload: {
      type: 'OUTFIT_REMINDER',
      title: 'Outfit reminder',
      description: 'Your planned outfit is coming up',
      frequency: 'once',
      date: triggerAt,
      priority: 'normal',
      enabled: true,
      nextTriggerAt: triggerAt,
    },
  });
};

export const cancelOutfitReminder = async ({ userId, calendarEntryId }) => {
  if (!calendarEntryId) return null;
  return deleteBySource({ userId, sourceType: 'outfit_calendar', sourceId: calendarEntryId });
};

export const syncLaundryReminder = async ({ userId, clothing }) => {
  const status = (clothing?.laundryStatus || '').toLowerCase();
  if (['clean', 'ready'].includes(status)) {
    return cancelLaundryReminder({ userId, clothingId: clothing?._id });
  }

  const triggerAt = clothing.nextWashDueAt
    ? new Date(clothing.nextWashDueAt)
    : new Date(Date.now() + 3 * DAY_MS);

  return upsertBySource({
    userId,
    sourceType: 'clothing',
    sourceId: clothing._id,
    payload: {
      type: 'LAUNDRY_REMINDER',
      title: 'Laundry reminder',
      description: 'You have clothes waiting for laundry',
      frequency: 'once',
      priority: 'normal',
      enabled: true,
      nextTriggerAt: triggerAt,
    },
  });
};

export const cancelLaundryReminder = async ({ userId, clothingId }) => {
  if (!clothingId) return null;
  return deleteBySource({ userId, sourceType: 'clothing', sourceId: clothingId });
};

export const syncTripReminder = async ({ userId, trip }) => {
  if (!trip?.startDate) return cancelTripReminder({ userId, tripId: trip?._id });

  const triggerAt = new Date(trip.startDate);
  triggerAt.setUTCDate(triggerAt.getUTCDate() - 1);

  if (triggerAt <= new Date()) {
    return cancelTripReminder({ userId, tripId: trip._id });
  }

  return upsertBySource({
    userId,
    sourceType: 'trip',
    sourceId: trip._id,
    payload: {
      type: 'TRIP_REMINDER',
      title: 'Trip reminder',
      description: `Your trip to ${trip.destination || trip.city || 'your destination'} starts soon`,
      frequency: 'once',
      priority: 'high',
      enabled: true,
      nextTriggerAt: triggerAt,
    },
  });
};

export const cancelTripReminder = async ({ userId, tripId }) => {
  if (!tripId) return null;
  await deleteBySource({ userId, sourceType: 'trip', sourceId: tripId });
  return cancelPackingReminder({ userId, tripId });
};

export const syncPackingReminder = async ({ userId, trip }) => {
  if (!trip?.startDate) return cancelPackingReminder({ userId, tripId: trip?._id });

  const triggerAt = new Date(trip.startDate);
  triggerAt.setUTCDate(triggerAt.getUTCDate() - 1);

  if (triggerAt <= new Date()) {
    return cancelPackingReminder({ userId, tripId: trip._id });
  }

  return upsertBySource({
    userId,
    sourceType: 'trip_packing',
    sourceId: trip._id,
    payload: {
      type: 'PACKING_REMINDER',
      title: 'Packing reminder',
      description: 'Check your packing list before your trip',
      frequency: 'once',
      priority: 'normal',
      enabled: true,
      nextTriggerAt: triggerAt,
    },
  });
};

export const cancelPackingReminder = async ({ userId, tripId }) => {
  if (!tripId) return null;
  return deleteBySource({ userId, sourceType: 'trip_packing', sourceId: tripId });
};
