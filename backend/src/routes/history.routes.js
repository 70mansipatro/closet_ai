import express from 'express';
import { protect } from '../middleware/auth.js';
import { listHistory, clothingHistory, outfitHistory, stats } from '../controllers/history.controller.js';

const router = express.Router();

router.get('/', protect, listHistory);
router.get('/stats', protect, stats);
router.get('/clothing/:id', protect, clothingHistory);
router.get('/outfit/:id', protect, outfitHistory);

export default router;
