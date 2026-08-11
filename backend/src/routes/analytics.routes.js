import express from 'express';
import { protect } from '../middleware/auth.js';
import { requirePremium } from '../middleware/requirePremium.js';
import {
  overview,
  wardrobe,
  wear,
  outfits,
  categories,
  colors,
  brands,
  laundry,
  costPerWear,
  sustainability,
  trends,
  unusedItems,
  insights,
} from '../controllers/analytics.controller.js';

const router = express.Router();

router.get('/overview', protect, overview);
router.get('/wardrobe', protect, wardrobe);
router.get('/wear', protect, wear);
router.get('/outfits', protect, outfits);
router.get('/categories', protect, categories);
router.get('/colors', protect, colors);
router.get('/brands', protect, brands);
router.get('/laundry', protect, laundry);
router.get('/cost-per-wear', protect, requirePremium, costPerWear);
router.get('/sustainability', protect, requirePremium, sustainability);
router.get('/trends', protect, trends);
router.get('/unused-items', protect, unusedItems);
router.get('/insights', protect, requirePremium, insights);

export default router;
