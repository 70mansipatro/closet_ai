import express from 'express';
import { protect } from '../middleware/auth.js';
import { checkFeatureLimit } from '../middleware/featureLimit.js';
import {
  addPackingItemHandler,
  createTripHandler,
  deletePackingItemHandler,
  deleteTripHandler,
  generatePacking,
  generateTripOutfitsHandler,
  getPacking,
  getTrip,
  listTrips,
  regeneratePackingHandler,
  togglePackingItemHandler,
  updatePackingItemHandler,
  updateTripHandler,
} from '../controllers/trip.controller.js';

const router = express.Router();

/**
 * @swagger
 * /trips:
 *   post:
 *     summary: Create a new trip
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - tripName
 *               - destination
 *               - country
 *               - city
 *               - startDate
 *               - endDate
 *             properties:
 *               tripName:
 *                 type: string
 *               destination:
 *                 type: string
 *               country:
 *                 type: string
 *               city:
 *                 type: string
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               activities:
 *                 type: array
 *                 items:
 *                   type: string
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Trip created successfully
 */
router.post('/', protect, checkFeatureLimit('trip'), createTripHandler);

/**
 * @swagger
 * /trips:
 *   get:
 *     summary: List trips for the authenticated user
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of trips returned successfully
 */
router.get('/', protect, listTrips);

/**
 * @swagger
 * /trips/{id}:
 *   get:
 *     summary: Retrieve a trip by ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trip returned successfully
 */
router.get('/:id', protect, getTrip);

/**
 * @swagger
 * /trips/{id}:
 *   put:
 *     summary: Update a trip
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               tripName:
 *                 type: string
 *               destination:
 *                 type: string
 *               country:
 *                 type: string
 *               city:
 *                 type: string
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               activities:
 *                 type: array
 *                 items:
 *                   type: string
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: Trip updated successfully
 */
router.put('/:id', protect, updateTripHandler);

/**
 * @swagger
 * /trips/{id}:
 *   delete:
 *     summary: Delete a trip
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trip deleted successfully
 */
router.delete('/:id', protect, deleteTripHandler);

/**
 * @swagger
 * /trips/{id}/packing/generate:
 *   post:
 *     summary: Generate an AI-powered packing list for a trip
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Packing list generated successfully
 */
router.post('/:id/packing/generate', protect, checkFeatureLimit('trip'), generatePacking);

/**
 * @swagger
 * /trips/{id}/packing:
 *   get:
 *     summary: Get the packing list for a trip
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Packing list returned successfully
 */
router.get('/:id/packing', protect, getPacking);

/**
 * @swagger
 * /trips/{id}/packing/add:
 *   post:
 *     summary: Add a manual item to the trip packing list
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               category:
 *                 type: string
 *               quantity:
 *                 type: integer
 *               packed:
 *                 type: boolean
 *               required:
 *                 type: boolean
 *               reason:
 *                 type: string
 *     responses:
 *       201:
 *         description: Manual packing item added successfully
 */
router.post('/:id/packing/add', protect, addPackingItemHandler);

/**
 * @swagger
 * /trips/{id}/packing/{itemId}:
 *   put:
 *     summary: Update a packing item
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               category:
 *                 type: string
 *               quantity:
 *                 type: integer
 *               packed:
 *                 type: boolean
 *               required:
 *                 type: boolean
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Packing item updated successfully
 */
router.put('/:id/packing/:itemId', protect, updatePackingItemHandler);

/**
 * @swagger
 * /trips/{id}/packing/{itemId}:
 *   delete:
 *     summary: Delete a packing item
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Packing item deleted successfully
 */
router.delete('/:id/packing/:itemId', protect, deletePackingItemHandler);

/**
 * @swagger
 * /trips/{id}/packing/{itemId}/toggle:
 *   put:
 *     summary: Toggle packed status of a packing item
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Packing item toggle updated successfully
 */
router.put('/:id/packing/:itemId/toggle', protect, togglePackingItemHandler);

/**
 * @swagger
 * /trips/{id}/packing/regenerate:
 *   post:
 *     summary: Regenerate the AI packing list for a trip
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Packing list regenerated successfully
 */
router.post('/:id/packing/regenerate', protect, regeneratePackingHandler);

/**
 * @swagger
 * /trips/{id}/outfits/generate:
 *   post:
 *     summary: Generate trip outfits based on destination and wardrobe
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trip outfits generated successfully
 */
router.post('/:id/outfits/generate', protect, generateTripOutfitsHandler);

export default router;
