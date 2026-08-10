import { AppError } from '../utils/appError.js';
import {
  laundryBulkStatusSchema,
  laundryHistoryQuerySchema,
  laundryListQuerySchema,
  laundryStatusSchema,
} from '../validators/laundry.validator.js';
import {
  bulkUpdateLaundryStatus,
  buildLaundryStatistics,
  changeLaundryStatus,
  dryClothing,
  getLaundryHistory,
  getLaundryHistoryForClothing,
  getLaundryItem,
  listLaundryItems,
  ironClothing,
  washClothing,
} from '../services/laundry.service.js';

export const listLaundry = async (req, res, next) => {
  try {
    const { error, value } = laundryListQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await listLaundryItems({ userId: req.user._id, ...value });
    res.status(200).json({ success: true, data: result.items, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const getLaundry = async (req, res, next) => {
  try {
    const item = await getLaundryItem({ userId: req.user._id, clothingId: req.params.clothingId });
    if (!item) throw new AppError('Clothing item not found', 404);
    res.status(200).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
};

export const updateLaundryStatus = async (req, res, next) => {
  try {
    const { error, value } = laundryStatusSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const updated = await changeLaundryStatus({
      userId: req.user._id,
      clothingId: req.params.clothingId,
      newStatus: value.newStatus,
      method: value.method,
      notes: value.notes,
      explicit: true,
    });

    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
};

export const washLaundry = async (req, res, next) => {
  try {
    const { error, value } = laundryStatusSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const updated = await washClothing({
      userId: req.user._id,
      clothingId: req.params.clothingId,
      method: value.method || 'wash',
      notes: value.notes,
    });

    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
};

export const dryLaundry = async (req, res, next) => {
  try {
    const { error, value } = laundryStatusSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const updated = await dryClothing({
      userId: req.user._id,
      clothingId: req.params.clothingId,
      method: value.method || 'dry',
      notes: value.notes,
    });

    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
};

export const ironLaundry = async (req, res, next) => {
  try {
    const { error, value } = laundryStatusSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const updated = await ironClothing({
      userId: req.user._id,
      clothingId: req.params.clothingId,
      method: value.method || 'iron',
      notes: value.notes,
    });

    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    next(error);
  }
};

export const bulkLaundryStatus = async (req, res, next) => {
  try {
    const { error, value } = laundryBulkStatusSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const result = await bulkUpdateLaundryStatus({
      userId: req.user._id,
      clothingIds: value.clothingIds,
      newStatus: value.newStatus,
      method: value.method,
      notes: value.notes,
    });

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const laundryHistory = async (req, res, next) => {
  try {
    const { error, value } = laundryHistoryQuerySchema.validate({
      ...req.query,
      clothingId: req.params.clothingId ?? req.query.clothingId,
    });
    if (error) throw new AppError(error.details[0].message, 400);

    if (req.params.clothingId) {
      const items = await getLaundryHistoryForClothing({ userId: req.user._id, clothingId: req.params.clothingId });
      res.status(200).json({ success: true, data: items });
      return;
    }

    const result = await getLaundryHistory({ userId: req.user._id, ...value });
    res.status(200).json({ success: true, data: result.items, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const laundryStatistics = async (req, res, next) => {
  try {
    const data = await buildLaundryStatistics({ userId: req.user._id });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
