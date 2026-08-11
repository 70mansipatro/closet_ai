import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  listRemindersHandler,
  getReminderHandler,
  createReminderHandler,
  updateReminderHandler,
  deleteReminderHandler,
  toggleReminderHandler,
  snoozeReminderHandler,
} from '../controllers/reminder.controller.js';

const router = express.Router();

router.get('/', protect, listRemindersHandler);
router.post('/', protect, createReminderHandler);
router.get('/:id', protect, getReminderHandler);
router.patch('/:id', protect, updateReminderHandler);
router.delete('/:id', protect, deleteReminderHandler);
router.patch('/:id/toggle', protect, toggleReminderHandler);
router.post('/:id/snooze', protect, snoozeReminderHandler);

export default router;
