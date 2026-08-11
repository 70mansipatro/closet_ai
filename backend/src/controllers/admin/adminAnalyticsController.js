import { AppError } from '../../utils/appError.js';
import { revenueQuerySchema, analyticsQuerySchema } from '../../validators/admin.validator.js';
import { getRevenueSummary, getRevenueTrend } from '../../services/admin/adminRevenueService.js';
import * as adminAnalyticsService from '../../services/admin/adminAnalyticsService.js';
import { getDashboardSummary } from '../../services/admin/adminDashboardService.js';

const validateAndGet = async (req, fn) => {
  const { error, value } = analyticsQuerySchema.validate(req.query);
  if (error) throw new AppError(error.details[0].message, 400);
  return fn(value);
};

export const getRevenue = async (req, res, next) => {
  try {
    const { error, value } = revenueQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const [summary, trend] = await Promise.all([getRevenueSummary(), getRevenueTrend(value)]);
    res.status(200).json({ success: true, data: { summary, trend } });
  } catch (error) {
    next(error);
  }
};

export const getOverview = async (req, res, next) => {
  try {
    const data = await getDashboardSummary({ range: req.query.range });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getUserAnalytics = async (req, res, next) => {
  try {
    const data = await validateAndGet(req, adminAnalyticsService.getUserAnalytics);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getRevenueAnalytics = async (req, res, next) => {
  try {
    const { error, value } = revenueQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);
    const trend = await getRevenueTrend(value);
    res.status(200).json({ success: true, data: { trend } });
  } catch (error) {
    next(error);
  }
};

export const getSubscriptionAnalytics = async (req, res, next) => {
  try {
    const data = await getDashboardSummary({ range: req.query.range });
    res.status(200).json({ success: true, data: data.subscriptions });
  } catch (error) {
    next(error);
  }
};

export const getAiAnalytics = async (req, res, next) => {
  try {
    const data = await validateAndGet(req, adminAnalyticsService.getAiAnalytics);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getWardrobeAnalytics = async (req, res, next) => {
  try {
    const data = await validateAndGet(req, adminAnalyticsService.getWardrobeAnalytics);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getOutfitAnalytics = async (req, res, next) => {
  try {
    const data = await validateAndGet(req, adminAnalyticsService.getOutfitAnalytics);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getLaundryAnalytics = async (req, res, next) => {
  try {
    const data = await adminAnalyticsService.getLaundryAnalytics();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getTripAnalytics = async (req, res, next) => {
  try {
    const data = await adminAnalyticsService.getTripAnalytics();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
