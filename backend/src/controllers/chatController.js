import { AppError } from '../utils/appError.js';
import {
  createConversation,
  deleteConversation,
  deleteMessage,
  getConversation,
  listConversations,
  listMessages,
  sendMessage,
} from '../services/chatService.js';

export const createConversationHandler = async (req, res, next) => {
  try {
    const conversation = await createConversation({ userId: req.user._id, payload: req.body || {} });
    res.status(201).json({ success: true, data: conversation });
  } catch (error) {
    next(error);
  }
};

export const listConversationHandler = async (req, res, next) => {
  try {
    const result = await listConversations({ userId: req.user._id, page: req.query.page, limit: req.query.limit });
    res.status(200).json({ success: true, data: result.conversations, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const getConversationHandler = async (req, res, next) => {
  try {
    const conversation = await getConversation({ userId: req.user._id, conversationId: req.params.conversationId });
    res.status(200).json({ success: true, data: conversation });
  } catch (error) {
    next(error);
  }
};

export const deleteConversationHandler = async (req, res, next) => {
  try {
    await deleteConversation({ userId: req.user._id, conversationId: req.params.conversationId });
    res.status(200).json({ success: true, message: 'Conversation deleted' });
  } catch (error) {
    next(error);
  }
};

export const listMessagesHandler = async (req, res, next) => {
  try {
    const result = await listMessages({ userId: req.user._id, conversationId: req.params.conversationId, page: req.query.page, limit: req.query.limit });
    res.status(200).json({ success: true, data: result.messages, pagination: result.pagination });
  } catch (error) {
    next(error);
  }
};

export const sendMessageHandler = async (req, res, next) => {
  try {
    const result = await sendMessage({ userId: req.user._id, conversationId: req.params.conversationId, payload: req.body || {} });
    res.status(200).json({ success: true, message: result.message });
  } catch (error) {
    next(error);
  }
};

export const deleteMessageHandler = async (req, res, next) => {
  try {
    await deleteMessage({ userId: req.user._id, conversationId: req.params.conversationId, messageId: req.params.messageId });
    res.status(200).json({ success: true, message: 'Message deleted' });
  } catch (error) {
    next(error);
  }
};
