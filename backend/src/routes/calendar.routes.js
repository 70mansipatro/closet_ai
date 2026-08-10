import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  schedule,
  list,
  getByDate,
  update,
  remove,
  wearToday,
} from '../controllers/calendar.controller.js';

const router = express.Router();

router.post('/schedule', protect, schedule);
router.get('/', protect, list);
router.get('/:date', protect, getByDate);
router.put('/:id', protect, update);
router.delete('/:id', protect, remove);
router.post('/wear-today', protect, wearToday);

export default router;
