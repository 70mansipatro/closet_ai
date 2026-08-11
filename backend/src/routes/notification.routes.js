import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  listNotificationsHandler,
  unreadCountHandler,
  getNotificationHandler,
  markReadHandler,
  markAllReadHandler,
  deleteNotificationHandler,
  deleteAllNotificationsHandler,
  getPreferencesHandler,
  updatePreferencesHandler,
  getSmartSettingsHandler,
  updateSmartSettingsHandler,
} from '../controllers/notification.controller.js';

const router = express.Router();

router.get('/unread-count', protect, unreadCountHandler);
router.get('/preferences', protect, getPreferencesHandler);
router.patch('/preferences', protect, updatePreferencesHandler);
router.get('/smart-settings', protect, getSmartSettingsHandler);
router.patch('/smart-settings', protect, updateSmartSettingsHandler);
router.patch('/read-all', protect, markAllReadHandler);
router.delete('/', protect, deleteAllNotificationsHandler);

router.get('/', protect, listNotificationsHandler);
router.get('/:id', protect, getNotificationHandler);
router.patch('/:id/read', protect, markReadHandler);
router.delete('/:id', protect, deleteNotificationHandler);

export default router;
