import NotificationPreference from '../models/NotificationPreference.js';
import SmartReminderSetting from '../models/SmartReminderSetting.js';
import OutfitCalendar from '../models/OutfitCalendar.js';
import Clothing from '../models/Clothing.js';
import Trip from '../models/Trip.js';
import PackingList from '../models/PackingList.js';
import WearHistory from '../models/WearHistory.js';
import ChatConversation from '../models/ChatConversation.js';
import User from '../models/User.js';
import { getUserSubscriptionStatus } from './subscriptionService.js';
import { isWithinQuietHours } from './notification.service.js';
import { existsDuplicate, createOne, countTodayForUser } from '../repositories/notification.repository.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const startOfDay = (d = new Date()) => {
  const t = new Date(d);
  t.setUTCHours(0, 0, 0, 0);
  return t;
};
const startOfWeek = (d = new Date()) => new Date(startOfDay(d).getTime() - 7 * DAY_MS);

// ---- Per-category rule evaluators. Each returns a candidate notification or null. ----

const evaluateOutfitRule = async (userId) => {
  const tomorrow = startOfDay(new Date(Date.now() + DAY_MS));
  const entry = await OutfitCalendar.findOne({ userId, date: tomorrow, status: 'Planned' }).lean();
  if (!entry) return null;

  const prepared = Boolean(entry.outfitId || entry.topId || entry.bottomId);
  return {
    type: 'OUTFIT_REMINDER',
    title: prepared ? 'Outfit ready for tomorrow' : 'Outfit not prepared',
    message: prepared
      ? 'Your outfit for tomorrow is ready.'
      : "Your planned outfit for tomorrow hasn't been prepared yet.",
    sourceType: 'outfit_calendar',
    sourceId: entry._id,
    priority: 'normal',
    actionType: 'navigate',
    actionRoute: '/calendar',
  };
};

const evaluateLaundryRule = async (userId) => {
  const now = new Date();
  const overdueCount = await Clothing.countDocuments({
    userId,
    $or: [
      { nextWashDueAt: { $lte: now } },
      { lastWashedAt: { $lte: new Date(now.getTime() - 30 * DAY_MS) } },
    ],
    laundryStatus: { $nin: ['clean', 'ready'] },
  });
  if (overdueCount <= 0) return null;

  return {
    type: 'LAUNDRY_REMINDER',
    title: 'Laundry overdue',
    message:
      overdueCount === 1
        ? 'Your laundry task is overdue.'
        : `You have ${overdueCount} clothes waiting for laundry.`,
    sourceType: 'laundry',
    sourceId: null,
    priority: 'normal',
    actionType: 'navigate',
    actionRoute: '/laundry',
  };
};

const evaluateTripRule = async (userId) => {
  const now = new Date();
  const trip = await Trip.findOne({
    owner: userId,
    startDate: { $gte: now, $lte: new Date(now.getTime() + 3 * DAY_MS) },
  })
    .sort({ startDate: 1 })
    .lean();
  if (!trip) return null;

  const daysUntil = Math.ceil((new Date(trip.startDate) - now) / DAY_MS);
  const message =
    daysUntil <= 1
      ? 'Your trip starts tomorrow. Check your packing list.'
      : `Your trip to ${trip.destination} starts in ${daysUntil} days.`;

  return {
    type: 'TRIP_REMINDER',
    title: 'Upcoming trip',
    message,
    sourceType: 'trip',
    sourceId: trip._id,
    priority: daysUntil <= 1 ? 'high' : 'normal',
    actionType: 'navigate',
    actionRoute: '/trips',
  };
};

const evaluatePackingRule = async (userId) => {
  const now = new Date();
  const trip = await Trip.findOne({
    owner: userId,
    startDate: { $gte: now, $lte: new Date(now.getTime() + 2 * DAY_MS) },
  })
    .sort({ startDate: 1 })
    .lean();
  if (!trip) return null;

  const [total, packed] = await Promise.all([
    PackingList.countDocuments({ tripId: trip._id }),
    PackingList.countDocuments({ tripId: trip._id, packed: true }),
  ]);
  if (total === 0 || packed >= total) return null;

  const percent = Math.round((packed / total) * 100);
  const daysUntil = Math.ceil((new Date(trip.startDate) - now) / DAY_MS);

  return {
    type: 'PACKING_REMINDER',
    title: 'Packing incomplete',
    message:
      daysUntil <= 1
        ? 'Your trip is tomorrow and packing is incomplete.'
        : `Your packing list is only ${percent}% complete.`,
    sourceType: 'trip_packing',
    sourceId: trip._id,
    priority: daysUntil <= 1 ? 'high' : 'normal',
    actionType: 'navigate',
    actionRoute: '/packing',
  };
};

const evaluateWearHistoryRule = async (userId) => {
  const today = startOfDay(new Date());
  const loggedToday = await WearHistory.findOne({ userId, date: { $gte: today } }).lean();
  if (loggedToday) return null;

  return {
    type: 'WEAR_HISTORY_REMINDER',
    title: "Log today's outfit",
    message: "You haven't logged today's outfit.",
    sourceType: 'wear_history_daily',
    sourceId: null,
    priority: 'low',
    actionType: 'navigate',
    actionRoute: '/history/wear',
  };
};

const evaluateWardrobeRule = async (userId) => {
  const cutoff = new Date(Date.now() - 60 * DAY_MS);
  const unusedCount = await Clothing.countDocuments({
    userId,
    $or: [{ lastWorn: { $exists: false } }, { lastWorn: { $lte: cutoff } }],
  });
  if (unusedCount < 5) return null;

  return {
    type: 'WARDROBE_REMINDER',
    title: 'Wardrobe insight',
    message: `You have ${unusedCount} clothes that haven't been worn recently.`,
    sourceType: 'wardrobe_unused',
    sourceId: null,
    priority: 'low',
    actionType: 'navigate',
    actionRoute: '/wardrobe',
  };
};

const evaluateAiStylistRule = async (userId) => {
  const lastConversation = await ChatConversation.findOne({ userId }).sort({ lastMessageAt: -1 }).lean();
  const cutoff = new Date(Date.now() - 7 * DAY_MS);
  if (lastConversation && new Date(lastConversation.lastMessageAt) > cutoff) return null;

  return {
    type: 'AI_STYLIST_REMINDER',
    title: 'Try AI Stylist',
    message: "You haven't used AI Stylist recently.",
    sourceType: 'ai_stylist_inactivity',
    sourceId: null,
    priority: 'low',
    actionType: 'navigate',
    actionRoute: '/ai/stylist',
  };
};

const evaluateSubscriptionRule = async (userId) => {
  const status = await getUserSubscriptionStatus(userId);
  if (!status || status.plan === 'free' || !status.endDate) return null;
  if (status.status !== 'active') return null;
  if (![7, 3, 1].includes(status.daysRemaining)) return null;

  return {
    type: 'PREMIUM_EXPIRY',
    title: 'Premium expiring soon',
    message: `Your ClosetAI Premium plan expires in ${status.daysRemaining} day${status.daysRemaining === 1 ? '' : 's'}.`,
    sourceType: 'subscription',
    sourceId: null,
    priority: status.daysRemaining <= 1 ? 'high' : 'normal',
    actionType: 'navigate',
    actionRoute: '/subscription',
  };
};

const DAILY_RULES = [
  { key: 'smartTrip', prefKey: 'tripReminders', evaluate: evaluateTripRule, windowMs: DAY_MS },
  { key: 'smartPacking', prefKey: 'packingReminders', evaluate: evaluatePackingRule, windowMs: DAY_MS },
  { key: 'smartOutfit', prefKey: 'outfitReminders', evaluate: evaluateOutfitRule, windowMs: DAY_MS },
  { key: 'smartLaundry', prefKey: 'laundryReminders', evaluate: evaluateLaundryRule, windowMs: DAY_MS },
  { key: null, prefKey: 'premiumExpiryReminders', evaluate: evaluateSubscriptionRule, windowMs: DAY_MS },
  { key: 'smartWearHistory', prefKey: 'wearHistoryReminders', evaluate: evaluateWearHistoryRule, windowMs: DAY_MS },
  { key: 'smartAIStylist', prefKey: 'aiStylistReminders', evaluate: evaluateAiStylistRule, windowMs: DAY_MS },
];

const WEEKLY_RULES = [
  { key: 'smartWardrobe', prefKey: 'wardrobeReminders', evaluate: evaluateWardrobeRule, windowMs: 7 * DAY_MS },
];

export const evaluateUserSmartReminders = async ({ userId, cadence = 'daily' }) => {
  const [preferences, smartSettings] = await Promise.all([
    NotificationPreference.findOne({ userId }).lean(),
    SmartReminderSetting.findOne({ userId }).lean(),
  ]);

  if (preferences && preferences.smartReminders === false) return { created: 0 };
  if (smartSettings && smartSettings.enabled === false) return { created: 0 };

  const effectivePreferences = preferences || {};
  const effectiveSettings = smartSettings || {};
  const maxDaily = effectiveSettings.maxDailyReminders ?? 3;
  const minInterval = (effectiveSettings.minimumIntervalMinutes ?? 120) * 60 * 1000;

  const todaySince = startOfDay();
  const sentToday = await countTodayForUser({ userId, since: todaySince });
  if (sentToday >= maxDaily) return { created: 0 };

  const inQuietHours = isWithinQuietHours(effectivePreferences);

  const rules = cadence === 'weekly' ? WEEKLY_RULES : DAILY_RULES;
  let created = 0;
  let remainingBudget = maxDaily - sentToday;

  for (const rule of rules) {
    if (remainingBudget <= 0) break;
    if (rule.key && effectiveSettings[rule.key] === false) continue;
    if (rule.prefKey && effectivePreferences[rule.prefKey] === false) continue;

    let candidate;
    try {
      candidate = await rule.evaluate(userId);
    } catch (error) {
      console.error('[SMART REMINDER] rule evaluation failed', { userId, rule: rule.key, error: error.message });
      continue;
    }
    if (!candidate) continue;

    if (inQuietHours && candidate.priority !== 'urgent') continue;

    const since = new Date(Date.now() - rule.windowMs);
    const isDuplicate = await existsDuplicate({
      userId,
      type: candidate.type,
      sourceId: candidate.sourceId,
      sourceType: candidate.sourceId ? undefined : candidate.sourceType,
      since,
    });
    if (isDuplicate) continue;

    await createOne({
      userId,
      type: candidate.type,
      title: candidate.title,
      message: candidate.message,
      body: candidate.message,
      data: { smart: true, rule: rule.key || candidate.sourceType },
      channel: ['IN_APP', 'LOCAL'],
      priority: candidate.priority,
      status: 'sent',
      sentAt: new Date(),
      sourceType: candidate.sourceType,
      sourceId: candidate.sourceId,
      actionType: candidate.actionType,
      actionRoute: candidate.actionRoute,
    });

    created += 1;
    remainingBudget -= 1;
  }

  return { created };
};

export const runSmartReminderCycle = async ({ cadence = 'daily', batchSize = 100 } = {}) => {
  let processed = 0;
  let totalCreated = 0;
  const cursor = User.find({ status: 'active' }).select('_id').lean().cursor();

  let batch = [];
  const flushBatch = async () => {
    if (!batch.length) return;
    const results = await Promise.allSettled(
      batch.map((user) => evaluateUserSmartReminders({ userId: user._id, cadence }))
    );
    results.forEach((result) => {
      if (result.status === 'fulfilled') totalCreated += result.value.created || 0;
    });
    processed += batch.length;
    batch = [];
  };

  for await (const user of cursor) {
    batch.push(user);
    if (batch.length >= batchSize) {
      await flushBatch();
    }
  }
  await flushBatch();

  return { processed, totalCreated };
};
