import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  createOutfit,
  listOutfits,
  getOutfit,
  updateOutfit,
  deleteOutfit,
  aiGenerateOutfits,
} from '../controllers/outfit.controller.js';

const router = express.Router();

router.post('/', protect, createOutfit);
router.get('/', protect, listOutfits);
router.get('/:id', protect, getOutfit);
router.put('/:id', protect, updateOutfit);
router.delete('/:id', protect, deleteOutfit);
router.post('/ai-generate', protect, aiGenerateOutfits);

export default router;
