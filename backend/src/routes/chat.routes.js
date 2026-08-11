import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  createConversationHandler,
  deleteConversationHandler,
  deleteMessageHandler,
  getConversationHandler,
  listConversationHandler,
  listMessagesHandler,
  sendMessageHandler,
} from '../controllers/chatController.js';

const router = express.Router();

router.post('/conversations', protect, createConversationHandler);
router.get('/conversations', protect, listConversationHandler);
router.get('/conversations/:conversationId', protect, getConversationHandler);
router.delete('/conversations/:conversationId', protect, deleteConversationHandler);
router.get('/conversations/:conversationId/messages', protect, listMessagesHandler);
router.post('/conversations/:conversationId/messages', protect, sendMessageHandler);
router.delete('/conversations/:conversationId/messages/:messageId', protect, deleteMessageHandler);

export default router;
