import mongoose from 'mongoose';
import { AppError } from '../utils/appError.js';
import Clothing from '../models/Clothing.js';
import {
  createLaundryHistory,
  findLaundryHistoryForUser,
  findLaundryHistoryByClothing,
  findRecentLaundryHistory,
} from '../repositories/laundry.repository.js';
import {
  createClothingItem,
  findClothingById,
  findClothingItems,
  updateClothingItem,
} from '../repositories/clothing.repository.js';
import { syncLaundryReminder } from './reminder.service.js';

const syncLaundryReminderSafely = async ({ userId, clothing }) => {
  try {
    await syncLaundryReminder({ userId, clothing });
  } catch (error) {
    console.error('[REMINDER HOOK] failed to sync laundry reminder', { userId, error: error.message });
  }
};

export const LAUNDRY_STATUSES = [
  'clean',
  'dirty',
  'washing',
  'drying',
  'ironing',
  'ready',
  'in-use',
  'repair',
];

export const AVAILABLE_LAUNDRY_STATUSES = ['clean', 'ready'];
export const UNAVAILABLE_LAUNDRY_STATUSES = ['dirty', 'washing', 'drying', 'ironing', 'in-use', 'repair'];

const normalizeStatus = (value) => (value ?? '').toString().trim().toLowerCase();

const ensureValidStatus = (status) => {
  const normalized = normalizeStatus(status);
  if (!LAUNDRY_STATUSES.includes(normalized)) {
    throw new AppError('Invalid laundry status', 400, { status });
  }
  return normalized;
};

const isStatusAvailable = (status) => AVAILABLE_LAUNDRY_STATUSES.includes(normalizeStatus(status));

const validateTransition = ({ currentStatus, nextStatus, explicit = false }) => {
  const normalizedCurrent = normalizeStatus(currentStatus);
  const normalizedNext = normalizeStatus(nextStatus);

  if (normalizedCurrent === normalizedNext) {
    throw new AppError('Clothing item is already in the requested status', 409);
  }

  if (explicit) {
    return true;
  }

  const allowed = {
    clean: ['dirty'],
    dirty: ['washing', 'clean'],
    washing: ['drying', 'clean'],
    drying: ['ironing'],
    ironing: ['ready', 'clean'],
    ready: ['clean', 'dirty'],
    'in-use': ['dirty', 'washing'],
    repair: ['clean', 'dirty'],
  };

  const possible = allowed[normalizedCurrent] || [];
  if (!possible.includes(normalizedNext)) {
    throw new AppError('Invalid laundry status transition', 409, { from: normalizedCurrent, to: normalizedNext });
  }
  return true;
};

const buildLaundryHistoryPayload = ({ userId, clothingId, previousStatus, newStatus, method, notes }) => ({
  userId,
  clothingId,
  previousStatus: normalizeStatus(previousStatus) || 'unknown',
  newStatus: normalizeStatus(newStatus),
  changedAt: new Date(),
  method: (method ?? '').toString().trim(),
  notes: (notes ?? '').toString().trim(),
});

const getNextWashDueAt = () => new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

export const listLaundryItems = async (query) => findClothingItems(query);

export const getLaundryItem = async ({ userId, clothingId }) => findClothingById({ userId, id: clothingId });

export const changeLaundryStatus = async ({ userId, clothingId, newStatus, method, notes, explicit = false, session = null }) => {
  const clothing = await findClothingById({ userId, id: clothingId });
  if (!clothing) {
    throw new AppError('Clothing item not found', 404);
  }

  const normalizedStatus = ensureValidStatus(newStatus);
  validateTransition({ currentStatus: clothing.laundryStatus, nextStatus: normalizedStatus, explicit });

  const updateData = { laundryStatus: normalizedStatus };
  if (normalizedStatus === 'clean') {
    updateData.lastWashedAt = new Date();
    updateData.nextWashDueAt = getNextWashDueAt();
    updateData.laundryCount = (clothing.laundryCount || 0) + 1;
  }

  const updated = await updateClothingItem({ userId, id: clothingId, updateData });
  if (!updated) {
    throw new AppError('Clothing item not found', 404);
  }

  const existingHistory = await findRecentLaundryHistory({
    userId,
    clothingId,
    newStatus: normalizedStatus,
    method: method ?? '',
    withinSeconds: 30,
  });

  if (!existingHistory) {
    await createLaundryHistory({
      payload: buildLaundryHistoryPayload({
        userId,
        clothingId,
        previousStatus: clothing.laundryStatus,
        newStatus: normalizedStatus,
        method,
        notes,
      }),
      session,
    });
  }

  await syncLaundryReminderSafely({ userId, clothing: updated });
  return updated;
};

export const washClothing = async ({ userId, clothingId, method, notes, session = null }) => {
  const clothing = await findClothingById({ userId, id: clothingId });
  if (!clothing) {
    throw new AppError('Clothing item not found', 404);
  }

  const normalizedStatus = 'clean';
  const updateData = {
    laundryStatus: normalizedStatus,
    lastWashedAt: new Date(),
    nextWashDueAt: getNextWashDueAt(),
    laundryCount: (clothing.laundryCount || 0) + 1,
  };
  const updated = await updateClothingItem({ userId, id: clothingId, updateData });

  const existingHistory = await findRecentLaundryHistory({
    userId,
    clothingId,
    newStatus: normalizedStatus,
    method: method ?? 'wash',
    withinSeconds: 30,
  });

  if (!existingHistory) {
    await createLaundryHistory({
      payload: buildLaundryHistoryPayload({
        userId,
        clothingId,
        previousStatus: clothing.laundryStatus,
        newStatus: normalizedStatus,
        method: method ?? 'wash',
        notes,
      }),
      session,
    });
  }

  await syncLaundryReminderSafely({ userId, clothing: updated });
  return updated;
};

export const dryClothing = async ({ userId, clothingId, method, notes, session = null }) => {
  const clothing = await findClothingById({ userId, id: clothingId });
  if (!clothing) {
    throw new AppError('Clothing item not found', 404);
  }

  validateTransition({ currentStatus: clothing.laundryStatus, nextStatus: 'drying', explicit: false });

  const updated = await updateClothingItem({
    userId,
    id: clothingId,
    updateData: { laundryStatus: 'drying' },
  });

  await createLaundryHistory({
    payload: buildLaundryHistoryPayload({
      userId,
      clothingId,
      previousStatus: clothing.laundryStatus,
      newStatus: 'drying',
      method: method ?? 'dry',
      notes,
    }),
    session,
  });

  await syncLaundryReminderSafely({ userId, clothing: updated });
  return updated;
};

export const ironClothing = async ({ userId, clothingId, method, notes, session = null }) => {
  const clothing = await findClothingById({ userId, id: clothingId });
  if (!clothing) {
    throw new AppError('Clothing item not found', 404);
  }

  validateTransition({ currentStatus: clothing.laundryStatus, nextStatus: 'ironing', explicit: false });

  const updated = await updateClothingItem({
    userId,
    id: clothingId,
    updateData: { laundryStatus: 'ironing' },
  });

  await createLaundryHistory({
    payload: buildLaundryHistoryPayload({
      userId,
      clothingId,
      previousStatus: clothing.laundryStatus,
      newStatus: 'ironing',
      method: method ?? 'iron',
      notes,
    }),
    session,
  });

  await syncLaundryReminderSafely({ userId, clothing: updated });
  return updated;
};

export const bulkUpdateLaundryStatus = async ({ userId, clothingIds, newStatus, method, notes, session = null }) => {
  const normalizedStatus = ensureValidStatus(newStatus);
  const items = await Clothing.find({ _id: { $in: clothingIds }, userId }).lean();

  const success = [];
  const failed = [];
  const itemMap = new Map(items.map((item) => [String(item._id), item]));

  for (const clothingId of clothingIds) {
    const clothing = itemMap.get(String(clothingId));
    if (!clothing) {
      failed.push({ clothingId, reason: 'Not found or not owned by user' });
      continue;
    }

    try {
      const updateData = { laundryStatus: normalizedStatus };
      if (normalizedStatus === 'clean') {
        updateData.lastWashedAt = new Date();
        updateData.nextWashDueAt = getNextWashDueAt();
        updateData.laundryCount = (clothing.laundryCount || 0) + 1;
      }

      const updated = await updateClothingItem({ userId, id: clothingId, updateData });
      if (!updated) {
        failed.push({ clothingId, reason: 'Update failed' });
        continue;
      }

      const existingHistory = await findRecentLaundryHistory({
        userId,
        clothingId,
        newStatus: normalizedStatus,
        method: method ?? 'bulk',
        withinSeconds: 30,
      });
      if (!existingHistory) {
        await createLaundryHistory({
          payload: buildLaundryHistoryPayload({
            userId,
            clothingId,
            previousStatus: clothing.laundryStatus,
            newStatus: normalizedStatus,
            method: method ?? 'bulk',
            notes,
          }),
          session,
        });
      }
      await syncLaundryReminderSafely({ userId, clothing: updated });
      success.push({ clothingId, status: normalizedStatus });
    } catch (error) {
      failed.push({ clothingId, reason: error.message || 'Failed to update' });
    }
  }

  return { success, failed };
};

export const getLaundryHistory = async (params) => findLaundryHistoryForUser(params);

export const getLaundryHistoryForClothing = async ({ userId, clothingId }) => findLaundryHistoryByClothing({ userId, clothingId });

export const buildLaundryStatistics = async ({ userId }) => {
  const stats = await Clothing.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: '$laundryStatus',
        count: { $sum: 1 },
      },
    },
  ]);

  const counts = {
    clean: 0,
    dirty: 0,
    washing: 0,
    drying: 0,
    ironing: 0,
    ready: 0,
    totalItems: 0,
    laundryDue: 0,
    recentlyWashed: 0,
    mostWashed: 0,
    neverWashed: 0,
  };

  stats.forEach((item) => {
    const key = normalizeStatus(item._id) || 'clean';
    if (counts[key] !== undefined) counts[key] = item.count;
    counts.totalItems += item.count;
  });

  const now = new Date();
  counts.laundryDue = await Clothing.countDocuments({
    userId,
    $or: [
      { nextWashDueAt: { $lte: now } },
      { lastWashedAt: { $lte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) } },
    ],
  });

  const recent = await Clothing.find({ userId, lastWashedAt: { $exists: true } })
    .sort({ lastWashedAt: -1 })
    .limit(5)
    .lean();

  counts.recentlyWashed = recent.length;

  const mostWashedItems = await Clothing.find({ userId })
    .sort({ laundryCount: -1 })
    .limit(5)
    .lean();
  counts.mostWashed = mostWashedItems.length;

  counts.neverWashed = await Clothing.countDocuments({
    userId,
    $or: [{ laundryCount: { $exists: false } }, { laundryCount: 0 }],
  });

  return {
    ...counts,
    recentlyWashedItems: recent,
    mostWashedItems,
  };
};
