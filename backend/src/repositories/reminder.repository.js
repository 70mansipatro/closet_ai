import Reminder from '../models/Reminder.js';

export const createReminder = async (payload) => Reminder.create(payload);

export const findRemindersForUser = async ({ userId, type, enabled }) => {
  const query = { userId };
  if (type) query.type = type;
  if (enabled !== undefined) query.enabled = enabled;
  return Reminder.find(query).sort({ nextTriggerAt: 1, createdAt: -1 }).lean();
};

export const findReminderById = async ({ userId, id }) => Reminder.findOne({ _id: id, userId });

export const updateReminder = async ({ userId, id, updateData }) =>
  Reminder.findOneAndUpdate({ _id: id, userId }, { $set: updateData }, { new: true, runValidators: true });

export const deleteReminder = async ({ userId, id }) => Reminder.findOneAndDelete({ _id: id, userId });

export const findBySource = async ({ userId, sourceType, sourceId }) =>
  Reminder.findOne({ userId, sourceType, sourceId });

export const deleteBySource = async ({ userId, sourceType, sourceId }) =>
  Reminder.deleteMany({ userId, sourceType, sourceId });

export const upsertBySource = async ({ userId, sourceType, sourceId, payload }) =>
  Reminder.findOneAndUpdate(
    { userId, sourceType, sourceId },
    { $set: { userId, sourceType, sourceId, ...payload } },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );

export const findDueReminders = async ({ now = new Date(), limit = 200 }) =>
  Reminder.find({ enabled: true, nextTriggerAt: { $lte: now } })
    .limit(limit)
    .lean();
