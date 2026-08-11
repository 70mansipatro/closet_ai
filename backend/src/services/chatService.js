import { AppError } from '../utils/appError.js';
import { buildContextForUser } from './contextBuilderService.js';
import { createConversationSchema, sendMessageSchema, validateObjectId } from '../validators/chatValidator.js';
import ChatConversation from '../models/ChatConversation.js';
import ChatMessage from '../models/ChatMessage.js';
import Clothing from '../models/Clothing.js';
import Outfit from '../models/Outfit.js';
import Trip from '../models/Trip.js';
import { getWeather } from './weather.service.js';

export const detectIntent = (message = '') => {
  const normalized = message.toLowerCase();
  if (normalized.includes('dirty') || normalized.includes('laundry') || normalized.includes('wash')) return 'LAUNDRY';
  if (normalized.includes('wear yesterday') || normalized.includes('worn recently') || normalized.includes('wear history') || normalized.includes('what did i wear')) return 'WEAR_HISTORY';
  if (normalized.includes('trip') || normalized.includes('pack') || normalized.includes('goa')) return 'PACKING';
  if (normalized.includes('weather') || normalized.includes('rain') || normalized.includes('hot') || normalized.includes('cold')) return 'WEATHER';
  if (normalized.includes('buy') || normalized.includes('shop')) return 'SHOPPING_ADVICE';
  if (normalized.includes('outfit') || normalized.includes('wear') || normalized.includes('shirt') || normalized.includes('clothes')) {
    if (normalized.includes('calendar') || normalized.includes('planned')) {
      return 'CALENDAR';
    }
    return 'OUTFIT_RECOMMENDATION';
  }
  return 'GENERAL_STYLE';
};

const sanitizeAndValidateResponse = (payload, wardrobeIds = []) => {
  const cleaned = {
    intent: payload?.intent || 'GENERAL_STYLE',
    message: typeof payload?.message === 'string' ? payload.message : 'Here is a tailored suggestion.',
    recommendations: Array.isArray(payload?.recommendations) ? payload.recommendations : [],
    actions: Array.isArray(payload?.actions) ? payload.actions : [],
  };

  const allowedIds = new Set(wardrobeIds);
  cleaned.recommendations = (cleaned.recommendations || []).map((recommendation) => {
    if (recommendation?.clothingIds) {
      recommendation.clothingIds = (recommendation.clothingIds || []).filter((id) => allowedIds.has(String(id)));
    }
    return recommendation;
  });

  return cleaned;
};

const generateStylistReply = async ({ userId, message, context }) => {
  const wardrobeItems = (context?.wardrobe || []).map((item) => ({
    _id: item._id,
    name: item.category,
    category: item.category,
    laundryStatus: item.laundryStatus,
    season: item.season,
    occasion: item.occasion,
    lastWorn: item.lastWorn,
    wearCount: item.wearCount || 0,
  }));

  const wardrobeIds = wardrobeItems.map((item) => String(item._id));
  const intent = detectIntent(message);

  const baseMessage = `You are ClosetAI Stylist. Use the user's wardrobe and recent history. Intent: ${intent}. Respond in JSON with keys intent, message, recommendations, actions. Use only clothing IDs that are present in the wardrobe context. If no suitable clothes, clearly say so. Avoid dirty items.`;
  const prompt = [baseMessage, JSON.stringify(context)].join('\n');

  if (process.env.GEMINI_API_KEY) {
    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL || 'gemini-2.0-flash'}:generateContent?key=${process.env.GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      });

      const data = await response.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
      const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());
      return sanitizeAndValidateResponse(parsed, wardrobeIds);
    } catch (error) {
      console.warn('[CHAT] Gemini fallback due to parsing error', error.message);
    }
  }

  const fallbackResponse = {
    intent,
    message: 'Here is a stylish recommendation based on your closet.',
    recommendations: wardrobeIds.length > 0 ? [{ type: 'outfit', clothingIds: wardrobeIds.slice(0, 3), reason: 'A practical outfit choice from your wardrobe.' }] : [],
    actions: [{ type: 'VIEW_OUTFIT', outfitId: '' }],
  };
  return sanitizeAndValidateResponse(fallbackResponse, wardrobeIds);
};

export const createConversation = async ({ userId, payload = {} }) => {
  const { error, value } = createConversationSchema.validate(payload);
  if (error) throw new AppError(error.details[0].message, 400);

  const conversation = await ChatConversation.create({ userId, title: value.title || 'New chat' });
  await ChatMessage.create({ conversationId: conversation._id, userId, role: 'system', content: 'Hi! I\'m your AI Stylist. What would you like help with?', messageType: 'text' });
  return conversation;
};

export const listConversations = async ({ userId, page = 1, limit = 20 }) => {
  const query = { userId };
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;
  const [conversations, totalItems] = await Promise.all([
    ChatConversation.find(query).sort({ updatedAt: -1 }).skip(skip).limit(safeLimit),
    ChatConversation.countDocuments(query),
  ]);
  return {
    conversations,
    pagination: { page: safePage, limit: safeLimit, totalItems, totalPages: Math.max(Math.ceil(totalItems / safeLimit), 1), hasMore: safePage < Math.max(Math.ceil(totalItems / safeLimit), 1) },
  };
};

export const getConversation = async ({ userId, conversationId }) => {
  validateObjectId(conversationId);
  const conversation = await ChatConversation.findOne({ _id: conversationId, userId });
  if (!conversation) throw new AppError('Conversation not found', 404);
  return conversation;
};

export const deleteConversation = async ({ userId, conversationId }) => {
  validateObjectId(conversationId);
  const conversation = await ChatConversation.findOne({ _id: conversationId, userId });
  if (!conversation) throw new AppError('Conversation not found', 404);
  await ChatMessage.deleteMany({ conversationId: conversation._id, userId });
  await conversation.deleteOne();
  return true;
};

export const listMessages = async ({ userId, conversationId, page = 1, limit = 30 }) => {
  validateObjectId(conversationId);
  const conversation = await ChatConversation.findOne({ _id: conversationId, userId });
  if (!conversation) throw new AppError('Conversation not found', 404);
  const safeLimit = Math.min(Math.max(Number(limit) || 30, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;
  const [messages, totalItems] = await Promise.all([
    ChatMessage.find({ conversationId }).sort({ createdAt: 1 }).skip(skip).limit(safeLimit),
    ChatMessage.countDocuments({ conversationId }),
  ]);
  return { messages, pagination: { page: safePage, limit: safeLimit, totalItems, totalPages: Math.max(Math.ceil(totalItems / safeLimit), 1), hasMore: safePage < Math.max(Math.ceil(totalItems / safeLimit), 1) } };
};

export const sendMessage = async ({ userId, conversationId, payload }) => {
  const { error, value } = sendMessageSchema.validate(payload);
  if (error) throw new AppError(error.details[0].message, 400);
  validateObjectId(conversationId);

  const conversation = await ChatConversation.findOne({ _id: conversationId, userId });
  if (!conversation) throw new AppError('Conversation not found', 404);

  const userMessage = await ChatMessage.create({ conversationId, userId, role: 'user', content: value.message, messageType: 'text' });
  const recentMessages = await ChatMessage.find({ conversationId }).sort({ createdAt: -1 }).limit(10).lean();
  const context = await buildContextForUser({ userId, message: value.message, recentMessages });
  const aiResponse = await generateStylistReply({ userId, message: value.message, context });

  const assistantMessage = await ChatMessage.create({
    conversationId,
    userId,
    role: 'assistant',
    content: aiResponse.message,
    messageType: aiResponse.recommendations.length > 0 ? 'outfit' : 'text',
    metadata: {
      intent: aiResponse.intent,
      recommendations: aiResponse.recommendations,
      actions: aiResponse.actions,
      wardrobeSnapshot: context?.wardrobe?.slice(0, 6) || [],
    },
  });

  conversation.lastMessage = aiResponse.message;
  conversation.lastMessageAt = new Date();
  await conversation.save();

  return { message: assistantMessage };
};

export const deleteMessage = async ({ userId, conversationId, messageId }) => {
  validateObjectId(conversationId);
  validateObjectId(messageId);
  const conversation = await ChatConversation.findOne({ _id: conversationId, userId });
  if (!conversation) throw new AppError('Conversation not found', 404);
  const message = await ChatMessage.findOne({ _id: messageId, conversationId, userId });
  if (!message) throw new AppError('Message not found', 404);
  await message.deleteOne();
  return true;
};
