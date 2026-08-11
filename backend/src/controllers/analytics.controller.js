import { AppError } from '../utils/appError.js';
import {
  getAnalyticsOverview,
  getWardrobeAnalytics,
  getWearAnalytics,
  getOutfitAnalytics,
  getCategoryAnalytics,
  getColorAnalytics,
  getBrandAnalytics,
  getLaundryAnalytics,
  getCostPerWearAnalytics,
  getSustainabilityAnalytics,
  getTrendAnalytics,
  getUnusedItems,
  buildAnalyticsInsights,
} from '../services/analytics.service.js';
import { analyticsQuerySchema } from '../validators/analytics.validator.js';

const parseDateQuery = (query) => ({
  from: query.from || null,
  to: query.to || null,
});

const validateQuery = (query) => {
  const { error, value } = analyticsQuerySchema.validate(query);
  if (error) {
    throw new AppError(error.details[0].message, 400);
  }
  return value;
};

export const overview = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getAnalyticsOverview({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const wardrobe = async (req, res, next) => {
  try {
    const data = await getWardrobeAnalytics({ userId: req.user._id });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const wear = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getWearAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const outfits = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getOutfitAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const categories = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getCategoryAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const colors = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getColorAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const brands = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getBrandAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const laundry = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getLaundryAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const costPerWear = async (req, res, next) => {
  try {
    const data = await getCostPerWearAnalytics({ userId: req.user._id });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const sustainability = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const data = await getSustainabilityAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const trends = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const interval = req.query.interval?.toString() ?? 'monthly';
    const data = await getTrendAnalytics({ userId: req.user._id, ...parseDateQuery(value), interval });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const unusedItems = async (req, res, next) => {
  try {
    const page = Number(req.query.page ?? 1);
    const limit = Number(req.query.limit ?? 20);
    const data = await getUnusedItems({ userId: req.user._id, page, limit });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const insights = async (req, res, next) => {
  try {
    const value = validateQuery(req.query);
    const overviewData = await getAnalyticsOverview({ userId: req.user._id, ...parseDateQuery(value) });
    const categoryData = await getCategoryAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    const colorData = await getColorAnalytics({ userId: req.user._id, ...parseDateQuery(value) });
    const wardrobeData = await getWardrobeAnalytics({ userId: req.user._id });
    const costData = await getCostPerWearAnalytics({ userId: req.user._id });
    const data = await buildAnalyticsInsights({ overview: overviewData, categoryStats: categoryData, colorStats: colorData, costStats: costData, wardrobeStats: wardrobeData });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
