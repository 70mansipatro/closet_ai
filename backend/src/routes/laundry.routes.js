import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  bulkLaundryStatus,
  dryLaundry,
  getLaundry,
  listLaundry,
  laundryHistory,
  laundryStatistics,
  ironLaundry,
  updateLaundryStatus,
  washLaundry,
} from '../controllers/laundry.controller.js';

const router = express.Router();

/**
 * @swagger
 * /laundry:
 *   get:
 *     summary: List laundry items for the authenticated user
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: laundryStatus
 *         schema:
 *           type: string
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *       - in: query
 *         name: color
 *         schema:
 *           type: string
 *       - in: query
 *         name: brand
 *         schema:
 *           type: string
 *       - in: query
 *         name: season
 *         schema:
 *           type: string
 *       - in: query
 *         name: occasion
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Laundry items returned successfully
 */
router.get('/', protect, listLaundry);

/**
 * @swagger
 * /laundry/{clothingId}:
 *   get:
 *     summary: Get single laundry clothing item by ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: clothingId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Clothing item details returned successfully
 */
router.get('/:clothingId', protect, getLaundry);

router.put('/:clothingId/status', protect, updateLaundryStatus);
router.post('/:clothingId/wash', protect, washLaundry);
router.post('/:clothingId/dry', protect, dryLaundry);
router.post('/:clothingId/iron', protect, ironLaundry);
router.put('/bulk-status', protect, bulkLaundryStatus);
router.get('/history', protect, laundryHistory);
router.get('/history/:clothingId', protect, laundryHistory);
router.get('/statistics', protect, laundryStatistics);

export default router;
