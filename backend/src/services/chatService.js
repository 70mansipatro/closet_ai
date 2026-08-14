import { AppError } from '../utils/appError.js';
import { buildContextForUser } from './contextBuilderService.js';
import { createConversationSchema, sendMessageSchema, validateObjectId } from '../validators/chatValidator.js';
import ChatConversation from '../models/ChatConversation.js';
import ChatMessage from '../models/ChatMessage.js';
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

const sanitizeAndValidateResponse = (payload, wardrobeIds = [], { isFallback = false } = {}) => {
  const allowedIds = new Set(wardrobeIds.map(String));

  const sanitizeRecommendationList = (list) =>
    (Array.isArray(list) ? list : [])
      .filter((item) => item && typeof item === 'object')
      .map((recommendation) => ({
        ...recommendation,
        clothingIds: Array.isArray(recommendation.clothingIds)
          ? recommendation.clothingIds.filter((id) => allowedIds.has(String(id)))
          : [],
      }));

  return {
    intent: typeof payload?.intent === 'string' ? payload.intent : 'GENERAL_STYLE',
    message: typeof payload?.message === 'string' ? payload.message : 'Here is a tailored suggestion.',
    recommendations: sanitizeRecommendationList(payload?.recommendations),
    alternatives: sanitizeRecommendationList(payload?.alternatives),
    missingItems: Array.isArray(payload?.missingItems) ? payload.missingItems.filter((item) => typeof item === 'string') : [],
    actions: {
      canSave: Boolean(payload?.actions?.canSave),
      canSchedule: Boolean(payload?.actions?.canSchedule),
      canWear: Boolean(payload?.actions?.canWear),
    },
    isFallback,
  };
};

const findUpcomingTripWeather = async (trips = []) => {
  const now = new Date();
  const trip = (trips || []).find((t) => t?.destination && t?.startDate && t?.endDate && new Date(t.endDate) >= now);
  if (!trip) return null;

  try {
    return await getWeather({ city: trip.destination, startDate: trip.startDate, endDate: trip.endDate });
  } catch (error) {
    console.warn('[CHAT] weather lookup failed', error.message);
    return null;
  }
};

const RESPONSE_CONTRACT = 'Respond with ONLY valid JSON (no markdown fences, no extra text) matching exactly this shape: {"intent": string, "message": string, "recommendations": [{"title": string, "clothingIds": string[], "occasion": string, "style": string, "weather": string, "temperature": number|null, "reason": string, "rating": number}], "alternatives": [], "missingItems": string[], "actions": {"canSave": boolean, "canSchedule": boolean, "canWear": boolean}}.';

const generateStylistReply = async ({ userId, message, context }) => {
  const wardrobeIds = (context?.wardrobe || []).map((item) => String(item._id));
  const intent = detectIntent(message);
  const weather = intent === 'PACKING' ? await findUpcomingTripWeather(context?.trips) : null;

  const weatherInstruction = weather
    ? `Known weather for the relevant trip: ${JSON.stringify(weather)}.`
    : 'No weather data is available right now — if weather is relevant to your answer, say plainly that it is unavailable instead of inventing it.';

  const baseMessage = [
    'You are ClosetAI Stylist, a personal fashion assistant.',
    `Detected intent: ${intent}.`,
    'Only use clothing IDs that appear in the "wardrobe" array below — never invent an item or ID. Items listed under "laundry" are dirty/unavailable and must never be recommended.',
    weatherInstruction,
    RESPONSE_CONTRACT,
  ].join(' ');

  const contextPayload = JSON.stringify({ ...context, weather });
  const prompt = [baseMessage, contextPayload].join('\n');

  const callGemini = async () => {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL || 'gemini-2.0-flash'}:generateContent?key=${process.env.GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    });
    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    return JSON.parse(text.replace(/```json|```/g, '').trim());
  };

  const callOpenAi = async () => {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${process.env.OPENAI_API_KEY}` },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        messages: [{ role: 'system', content: baseMessage }, { role: 'user', content: contextPayload }],
        temperature: 0.7,
        response_format: { type: 'json_object' },
      }),
    });
    const data = await response.json();
    const text = data?.choices?.[0]?.message?.content || '{}';
    return JSON.parse(text.replace(/```json|```/g, '').trim());
  };

  if (process.env.GEMINI_API_KEY) {
    try {
      return sanitizeAndValidateResponse(await callGemini(), wardrobeIds);
    } catch (error) {
      console.warn('[CHAT] Gemini call failed, trying next provider', error.message);
    }
  }

  if (process.env.OPENAI_API_KEY) {
    try {
      return sanitizeAndValidateResponse(await callOpenAi(), wardrobeIds);
    } catch (error) {
      console.warn('[CHAT] OpenAI fallback failed', error.message);
    }
  }

  const fallbackResponse = {
    intent,
    message: 'I ran into trouble reaching the stylist AI, so here is a safe suggestion from your closet instead.',
    recommendations: wardrobeIds.length > 0
      ? [{ title: 'Everyday Pick', clothingIds: wardrobeIds.slice(0, 3), occasion: '', style: '', weather: '', temperature: null, reason: 'A practical outfit choice from your wardrobe while the AI stylist is unavailable.', rating: 5 }]
      : [],
    alternatives: [],
    missingItems: wardrobeIds.length === 0 ? ['No clean, ready-to-wear items were found in your wardrobe.'] : [],
    actions: { canSave: wardrobeIds.length > 0, canSchedule: wardrobeIds.length > 0, canWear: wardrobeIds.length > 0 },
  };
  return sanitizeAndValidateResponse(fallbackResponse, wardrobeIds, { isFallback: true });
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
      alternatives: aiResponse.alternatives,
      missingItems: aiResponse.missingItems,
      actions: aiResponse.actions,
      isFallback: aiResponse.isFallback,
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
