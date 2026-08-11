import { AppError } from '../utils/appError.js';
import { createTripSchema, updateTripSchema } from '../validators/trip.validator.js';
import { createTrip, deleteTrip, findTripById, findTripsForUser, updateTrip } from '../repositories/trip.repository.js';
import {
  addManualPackingItem,
  deletePackingItem as deletePackingItemService,
  generatePackingList,
  listPackingList,
  togglePackingItem,
  updatePackingItem as updatePackingItemService,
} from '../services/packing.service.js';
import { generateTripOutfits } from '../services/trip.service.js';
import { syncTripReminder, syncPackingReminder, cancelTripReminder } from '../services/reminder.service.js';

const syncTripRemindersSafely = async ({ userId, trip }) => {
  try {
    await syncTripReminder({ userId, trip });
    await syncPackingReminder({ userId, trip });
  } catch (error) {
    console.error('[REMINDER HOOK] failed to sync trip reminders', { userId, error: error.message });
  }
};

const cancelTripRemindersSafely = async ({ userId, tripId }) => {
  try {
    await cancelTripReminder({ userId, tripId });
  } catch (error) {
    console.error('[REMINDER HOOK] failed to cancel trip reminders', { userId, error: error.message });
  }
};

export const createTripHandler = async (req, res, next) => {
  try {
    const { error, value } = createTripSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const trip = await createTrip({ payload: { ...value, owner: req.user._id } });
    await syncTripRemindersSafely({ userId: req.user._id, trip });
    res.status(201).json({ success: true, data: trip });
  } catch (error) {
    next(error);
  }
};

export const listTrips = async (req, res, next) => {
  try {
    const { search, status, sortBy, sortOrder, page, limit } = req.query;
    const result = await findTripsForUser({
      userId: req.user._id,
      search: search?.toString(),
      status: status?.toString(),
      sortBy: sortBy?.toString() || 'startDate',
      sortOrder: sortOrder?.toString() || 'asc',
      page: Number(page) || 1,
      limit: Number(limit) || 50,
    });
    res.status(200).json({ success: true, data: result.items, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const getTrip = async (req, res, next) => {
  try {
    const trip = await findTripById({ userId: req.user._id, id: req.params.id });
    if (!trip) throw new AppError('Trip not found', 404);
    res.status(200).json({ success: true, data: trip });
  } catch (error) {
    next(error);
  }
};

export const updateTripHandler = async (req, res, next) => {
  try {
    const { error, value } = updateTripSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const trip = await updateTrip({ userId: req.user._id, id: req.params.id, updateData: value });
    if (!trip) throw new AppError('Trip not found', 404);
    await syncTripRemindersSafely({ userId: req.user._id, trip });
    res.status(200).json({ success: true, data: trip });
  } catch (error) {
    next(error);
  }
};

export const deleteTripHandler = async (req, res, next) => {
  try {
    const trip = await deleteTrip({ userId: req.user._id, id: req.params.id });
    if (!trip) throw new AppError('Trip not found', 404);
    await cancelTripRemindersSafely({ userId: req.user._id, tripId: req.params.id });
    res.status(200).json({ success: true, message: 'Trip deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const generatePacking = async (req, res, next) => {
  try {
    const result = await generatePackingList({ userId: req.user._id, tripId: req.params.id });
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const getPacking = async (req, res, next) => {
  try {
    const packing = await listPackingList({ userId: req.user._id, tripId: req.params.id });
    res.status(200).json({ success: true, data: packing });
  } catch (error) {
    next(error);
  }
};

export const addPackingItemHandler = async (req, res, next) => {
  try {
    const item = await addManualPackingItem({ userId: req.user._id, tripId: req.params.id, payload: req.body });
    res.status(201).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
};

export const updatePackingItemHandler = async (req, res, next) => {
  try {
    const item = await updatePackingItemService({
      userId: req.user._id,
      tripId: req.params.id,
      itemId: req.params.itemId,
      updateData: req.body,
    });
    res.status(200).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
};

export const deletePackingItemHandler = async (req, res, next) => {
  try {
    await deletePackingItemService({ userId: req.user._id, tripId: req.params.id, itemId: req.params.itemId });
    res.status(200).json({ success: true, message: 'Packing item deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const togglePackingItemHandler = async (req, res, next) => {
  try {
    const item = await togglePackingItem({ userId: req.user._id, tripId: req.params.id, itemId: req.params.itemId });
    res.status(200).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
};

export const regeneratePackingHandler = async (req, res, next) => {
  try {
    const result = await generatePackingList({ userId: req.user._id, tripId: req.params.id });
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const generateTripOutfitsHandler = async (req, res, next) => {
  try {
    const result = await generateTripOutfits({ userId: req.user._id, tripId: req.params.id });
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};
