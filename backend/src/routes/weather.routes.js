import express from 'express';
import { protect } from '../middleware/auth.js';
import { getWeatherHandler } from '../controllers/weather.controller.js';

const router = express.Router();

/**
 * @swagger
 * /weather:
 *   get:
 *     summary: Get weather forecast for a destination and date range
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: city
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: country
 *         required: false
 *         schema:
 *           type: string
 *       - in: query
 *         name: startDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Weather information returned successfully
 */
router.get('/', protect, getWeatherHandler);

export default router;
