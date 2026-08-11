import express from 'express';
import { protect } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { requirePermission } from '../middleware/requirePermission.js';

import { getDashboard } from '../controllers/admin/adminDashboardController.js';
import {
  getUsers,
  getUserDetail,
  updateUserStatus,
  updateUserRole,
  deleteUser,
} from '../controllers/admin/adminUserController.js';
import { getSubscriptions, getSubscriptionDetail } from '../controllers/admin/adminSubscriptionController.js';
import { getPlans, createPlan, updatePlan, setPlanStatus } from '../controllers/admin/adminPlanController.js';
import { getPayments, getPaymentDetail } from '../controllers/admin/adminPaymentController.js';
import {
  getRevenue,
  getOverview,
  getUserAnalytics,
  getRevenueAnalytics,
  getSubscriptionAnalytics,
  getAiAnalytics,
  getWardrobeAnalytics,
  getOutfitAnalytics,
  getLaundryAnalytics,
  getTripAnalytics,
} from '../controllers/admin/adminAnalyticsController.js';
import { getReportTypes, exportReport } from '../controllers/admin/adminReportController.js';
import { getAuditLogs } from '../controllers/admin/adminAuditController.js';
import { getSettings, updateSettings } from '../controllers/admin/adminSettingsController.js';
import {
  getNotifications,
  getNotificationStats,
  createAnnouncement,
  listAnnouncements,
  cancelAnnouncement,
  getReminders,
  getReminderStats,
} from '../controllers/admin/adminNotificationController.js';

const router = express.Router();

router.use(protect, requireAdmin);

router.get('/dashboard', requirePermission('dashboard.view'), getDashboard);

router.get('/users', requirePermission('users.view'), getUsers);
router.get('/users/:id', requirePermission('users.view'), getUserDetail);
router.patch('/users/:id/status', requirePermission('users.suspend'), updateUserStatus);
router.patch('/users/:id/role', requirePermission('users.manage'), updateUserRole);
router.delete('/users/:id', requirePermission('users.delete'), deleteUser);

router.get('/subscriptions', requirePermission('subscriptions.view'), getSubscriptions);
router.get('/subscriptions/:id', requirePermission('subscriptions.view'), getSubscriptionDetail);

router.get('/plans', requirePermission('plans.view'), getPlans);
router.post('/plans', requirePermission('plans.manage'), createPlan);
router.patch('/plans/:id', requirePermission('plans.manage'), updatePlan);
router.patch('/plans/:id/status', requirePermission('plans.manage'), setPlanStatus);

router.get('/payments', requirePermission('payments.view'), getPayments);
router.get('/payments/:id', requirePermission('payments.view'), getPaymentDetail);

router.get('/revenue', requirePermission('analytics.view'), getRevenue);

router.get('/analytics/overview', requirePermission('analytics.view'), getOverview);
router.get('/analytics/users', requirePermission('analytics.view'), getUserAnalytics);
router.get('/analytics/revenue', requirePermission('analytics.view'), getRevenueAnalytics);
router.get('/analytics/subscriptions', requirePermission('analytics.view'), getSubscriptionAnalytics);
router.get('/analytics/ai', requirePermission('analytics.view'), getAiAnalytics);
router.get('/analytics/wardrobe', requirePermission('analytics.view'), getWardrobeAnalytics);
router.get('/analytics/outfits', requirePermission('analytics.view'), getOutfitAnalytics);
router.get('/analytics/laundry', requirePermission('analytics.view'), getLaundryAnalytics);
router.get('/analytics/trips', requirePermission('analytics.view'), getTripAnalytics);

router.get('/reports', requirePermission('reports.view'), getReportTypes);
router.post('/reports/export', requirePermission('reports.view'), exportReport);

router.get('/audit-logs', requirePermission('audit.view'), getAuditLogs);

router.get('/settings', requirePermission('settings.view'), getSettings);
router.patch('/settings', requirePermission('settings.manage'), updateSettings);

router.get('/notifications', requirePermission('notifications.view'), getNotifications);
router.get('/notifications/stats', requirePermission('notifications.view'), getNotificationStats);
router.get('/notifications/announcements', requirePermission('notifications.view'), listAnnouncements);
router.post('/notifications/announcement', requirePermission('notifications.send'), createAnnouncement);
router.patch('/notifications/:id/cancel', requirePermission('notifications.manage'), cancelAnnouncement);
router.get('/reminders', requirePermission('notifications.view'), getReminders);
router.get('/reminders/stats', requirePermission('notifications.view'), getReminderStats);

export default router;
