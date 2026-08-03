import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  createTrip,
  listTrips,
  getTrip,
  updateTrip,
  deleteTrip,
  addPackingItem,
  updatePackingItem,
  deletePackingItem,
} from '../controllers/trip.controller.js';

const router = express.Router();

router.post('/', protect, createTrip);
router.get('/', protect, listTrips);
router.get('/:id', protect, getTrip);
router.put('/:id', protect, updateTrip);
router.delete('/:id', protect, deleteTrip);
router.post('/:id/packing-list', protect, addPackingItem);
router.put('/:id/packing-list/:itemId', protect, updatePackingItem);
router.delete('/:id/packing-list/:itemId', protect, deletePackingItem);

export default router;
