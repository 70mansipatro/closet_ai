import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  cancelSubscriptionHandler,
  checkStatusHandler,
  createOrderHandler,
  getCurrentSubscriptionHandler,
  getPlansHandler,
  restoreSubscriptionHandler,
  verifyPaymentHandler,
  webhookHandler,
} from '../controllers/subscriptionController.js';

const router = express.Router();

router.get('/plans', protect, getPlansHandler);
router.get('/me', protect, getCurrentSubscriptionHandler);
router.post('/create-order', protect, createOrderHandler);
router.post('/verify-payment', protect, verifyPaymentHandler);
router.post('/cancel', protect, cancelSubscriptionHandler);
router.post('/restore', protect, restoreSubscriptionHandler);
router.post('/check-status', protect, checkStatusHandler);
router.post('/webhook', webhookHandler);

export default router;
