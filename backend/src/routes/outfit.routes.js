import express from 'express';
import { protect } from '../middleware/auth.js';
import { checkFeatureLimit } from '../middleware/featureLimit.js';
import {
  createOutfit,
  listOutfits,
  getOutfit,
  updateOutfit,
  deleteOutfit,
  generateOutfit,
  favoriteOutfit,
  aiGenerateOutfits,
  wearOutfit,
} from '../controllers/outfit.controller.js';

const router = express.Router();

router.post('/generate', protect, checkFeatureLimit('ai_outfit'), generateOutfit);
router.post('/save', protect, createOutfit);
router.post('/wear', protect, wearOutfit);
router.get('/', protect, listOutfits);
router.put('/favorite', protect, favoriteOutfit);
router.get('/:id', protect, getOutfit);
router.delete('/:id', protect, deleteOutfit);
router.put('/:id', protect, updateOutfit);
router.post('/ai-generate', protect, checkFeatureLimit('ai_outfit'), aiGenerateOutfits);

export default router;
