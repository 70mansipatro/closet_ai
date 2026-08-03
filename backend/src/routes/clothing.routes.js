import express from 'express';
import { protect } from '../middleware/auth.js';
import { uploadSingle } from '../middleware/upload.js';
import {
  createClothing,
  listClothing,
  getClothing,
  updateClothing,
  deleteClothing,
  toggleFavoriteClothing,
} from '../controllers/clothing.controller.js';

const router = express.Router();

router.post('/', protect, uploadSingle, createClothing);
router.get('/', protect, listClothing);
router.get('/:id', protect, getClothing);
router.put('/:id', protect, uploadSingle, updateClothing);
router.delete('/:id', protect, deleteClothing);
router.post('/:id/favorite', protect, toggleFavoriteClothing);

export default router;
