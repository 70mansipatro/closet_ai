import { Parser as CsvParser } from 'json2csv';
import User from '../../models/User.js';
import Subscription from '../../models/Subscription.js';
import PaymentTransaction from '../../models/PaymentTransaction.js';
import Clothing from '../../models/Clothing.js';
import Outfit from '../../models/Outfit.js';
import LaundryHistory from '../../models/LaundryHistory.js';
import Trip from '../../models/Trip.js';
import FeatureUsage from '../../models/FeatureUsage.js';
import { AppError } from '../../utils/appError.js';

const buildDateRange = (from, to) => {
  if (!from && !to) return null;
  const range = {};
  if (from) range.$gte = new Date(from);
  if (to) range.$lte = new Date(to);
  return range;
};

const REPORT_DATASETS = {
  users: async ({ from, to, status, role }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    if (status) match.status = status;
    if (role) match.role = role;
    return User.find(match).select('name email role status subscriptionStatus subscriptionPlan createdAt lastLoginAt').lean();
  },
  subscriptions: async ({ from, to, status, plan }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    if (status) match.status = status;
    if (plan) match.planType = plan;
    return Subscription.find(match).populate('userId', 'name email').lean();
  },
  payments: async ({ from, to, status }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    if (status) match.status = status;
    return PaymentTransaction.find(match).populate('userId', 'name email').lean();
  },
  revenue: async ({ from, to }) => {
    const match = { status: 'success' };
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    return PaymentTransaction.find(match).populate('userId', 'name email').lean();
  },
  ai_usage: async ({ from, to }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    return FeatureUsage.find(match).populate('userId', 'name email').lean();
  },
  wardrobe: async ({ from, to }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    return Clothing.find(match).populate('userId', 'name email').lean();
  },
  outfits: async ({ from, to }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    return Outfit.find(match).populate('userId', 'name email').lean();
  },
  laundry: async ({ from, to }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.changedAt = dateRange;
    return LaundryHistory.find(match).populate('userId', 'name email').lean();
  },
  trips: async ({ from, to }) => {
    const match = {};
    const dateRange = buildDateRange(from, to);
    if (dateRange) match.createdAt = dateRange;
    return Trip.find(match).populate('owner', 'name email').lean();
  },
};

const flattenForCsv = (rows) =>
  rows.map((row) => {
    const flat = { ...row };
    if (flat.userId && typeof flat.userId === 'object') {
      flat.userName = flat.userId.name;
      flat.userEmail = flat.userId.email;
      flat.userId = String(flat.userId._id || flat.userId);
    }
    if (flat.owner && typeof flat.owner === 'object') {
      flat.ownerName = flat.owner.name;
      flat.ownerEmail = flat.owner.email;
      flat.owner = String(flat.owner._id || flat.owner);
    }
    delete flat.password;
    delete flat.refreshToken;
    delete flat.otp;
    delete flat.otpExpiresAt;
    return flat;
  });

export const listReportTypes = () => Object.keys(REPORT_DATASETS);

export const generateReport = async ({ type, format = 'csv', from, to, status, plan, role }) => {
  const loader = REPORT_DATASETS[type];
  if (!loader) throw new AppError('Unknown report type', 400, { code: 'REPORT_FAILED' });
  if (format !== 'csv') throw new AppError('Only CSV export is supported', 400, { code: 'EXPORT_FAILED' });

  const rows = await loader({ from, to, status, plan, role });
  const flatRows = flattenForCsv(rows);

  if (flatRows.length === 0) {
    return { csv: '', filename: `${type}-report.csv`, count: 0 };
  }

  const parser = new CsvParser();
  const csv = parser.parse(flatRows);
  return { csv, filename: `${type}-report-${Date.now()}.csv`, count: flatRows.length };
};
