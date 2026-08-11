import cron from 'node-cron';
import NotificationPreference from '../models/NotificationPreference.js';
import Announcement from '../models/Announcement.js';
import User from '../models/User.js';
import { findDueReminders } from '../repositories/reminder.repository.js';
import { markReminderTriggered } from './reminder.service.js';
import { isWithinQuietHours } from './notification.service.js';
import { createOne, createMany, cleanupExpired, markExpired } from '../repositories/notification.repository.js';
import { runSmartReminderCycle } from './smartReminderService.js';

const REMINDER_TYPE_TO_PREFERENCE = {
  OUTFIT_REMINDER: 'outfitReminders',
  LAUNDRY_REMINDER: 'laundryReminders',
  TRIP_REMINDER: 'tripReminders',
  PACKING_REMINDER: 'packingReminders',
  WEAR_HISTORY_REMINDER: 'wearHistoryReminders',
  WARDROBE_REMINDER: 'wardrobeReminders',
  AI_STYLIST_REMINDER: 'aiStylistReminders',
  SUBSCRIPTION_REMINDER: 'subscriptionReminders',
};

const REMINDER_ACTION_ROUTES = {
  OUTFIT_REMINDER: '/calendar',
  LAUNDRY_REMINDER: '/laundry',
  TRIP_REMINDER: '/trips',
  PACKING_REMINDER: '/packing',
  WEAR_HISTORY_REMINDER: '/history/wear',
  WARDROBE_REMINDER: '/wardrobe',
  AI_STYLIST_REMINDER: '/ai/stylist',
  SUBSCRIPTION_REMINDER: '/subscription',
  CUSTOM: '',
};

export const processDueReminders = async () => {
  const now = new Date();
  const dueReminders = await findDueReminders({ now });
  let created = 0;

  for (const reminder of dueReminders) {
    try {
      const preferences = await NotificationPreference.findOne({ userId: reminder.userId }).lean();
      const prefKey = REMINDER_TYPE_TO_PREFERENCE[reminder.type];
      if (prefKey && preferences && preferences[prefKey] === false) {
        await markReminderTriggered({ reminder, now });
        continue;
      }

      const inQuietHours = isWithinQuietHours(preferences);
      if (inQuietHours && reminder.priority !== 'urgent') {
        // Defer: try again on the next scheduler tick instead of dropping it silently.
        continue;
      }

      await createOne({
        userId: reminder.userId,
        type: reminder.type,
        title: reminder.title,
        message: reminder.description || reminder.title,
        body: reminder.description || '',
        data: { reminderId: reminder._id },
        channel: preferences?.localEnabled === false ? ['IN_APP'] : ['IN_APP', 'LOCAL'],
        priority: reminder.priority || 'normal',
        status: 'sent',
        sentAt: now,
        sourceType: reminder.sourceType || '',
        sourceId: reminder.sourceId || null,
        actionType: 'navigate',
        actionRoute: REMINDER_ACTION_ROUTES[reminder.type] || '',
      });

      await markReminderTriggered({ reminder, now });
      created += 1;
    } catch (error) {
      console.error('[SCHEDULER] failed to process reminder', { reminderId: reminder._id, error: error.message });
    }
  }

  return { processed: dueReminders.length, created };
};

const resolveAudienceUserIds = async (announcement) => {
  if (announcement.targetAudience === 'specificUsers') {
    return announcement.targetUserIds.map((id) => String(id));
  }

  const match = { status: 'active' };
  if (announcement.targetAudience === 'premium') {
    match.subscriptionStatus = 'active';
  } else if (announcement.targetAudience === 'free') {
    match.subscriptionStatus = { $in: ['free', 'expired', 'cancelled', 'past_due'] };
  }

  const users = await User.find(match).select('_id').lean();
  return users.map((user) => String(user._id));
};

export const processDueAnnouncements = async () => {
  const now = new Date();
  const dueAnnouncements = await Announcement.find({ status: 'scheduled', scheduledAt: { $lte: now } }).lean();
  let created = 0;

  for (const announcement of dueAnnouncements) {
    try {
      const userIds = await resolveAudienceUserIds(announcement);
      const preferencesById = new Map(
        (await NotificationPreference.find({ userId: { $in: userIds } }).lean()).map((p) => [String(p.userId), p])
      );

      const payloads = userIds
        .filter((userId) => preferencesById.get(userId)?.adminAnnouncements !== false)
        .map((userId) => ({
          userId,
          type: 'ADMIN_ANNOUNCEMENT',
          title: announcement.title,
          message: announcement.message,
          body: announcement.message,
          data: { announcementId: announcement._id },
          channel: ['IN_APP'],
          priority: announcement.priority,
          status: 'sent',
          sentAt: now,
          expiresAt: announcement.expiresAt,
          sourceType: 'announcement',
          sourceId: announcement._id,
          actionType: 'none',
          actionRoute: '',
        }));

      if (payloads.length) await createMany(payloads);

      await Announcement.updateOne(
        { _id: announcement._id },
        { status: 'sent', sentAt: now, recipientCount: payloads.length }
      );
      created += payloads.length;
    } catch (error) {
      console.error('[SCHEDULER] failed to process announcement', { announcementId: announcement._id, error: error.message });
    }
  }

  return { announcements: dueAnnouncements.length, notificationsCreated: created };
};

export const runCleanup = async ({ retentionDays = 90 } = {}) => {
  const expired = await markExpired();
  const deleted = await cleanupExpired({ retentionDays });
  return { expiredMarked: expired.modifiedCount || 0, deleted };
};

let started = false;

export const startNotificationScheduler = () => {
  if (started) return;
  started = true;

  cron.schedule('*/5 * * * *', async () => {
    try {
      const result = await processDueReminders();
      const announcementResult = await processDueAnnouncements();
      if (result.created || announcementResult.notificationsCreated) {
        console.log('[SCHEDULER] tick', result, announcementResult);
      }
    } catch (error) {
      console.error('[SCHEDULER] reminder/announcement tick failed', error);
    }
  });

  cron.schedule('0 6 * * *', async () => {
    try {
      const result = await runSmartReminderCycle({ cadence: 'daily' });
      console.log('[SCHEDULER] daily smart reminder cycle', result);
    } catch (error) {
      console.error('[SCHEDULER] daily smart reminder cycle failed', error);
    }
  });

  cron.schedule('0 7 * * 1', async () => {
    try {
      const result = await runSmartReminderCycle({ cadence: 'weekly' });
      console.log('[SCHEDULER] weekly smart reminder cycle', result);
    } catch (error) {
      console.error('[SCHEDULER] weekly smart reminder cycle failed', error);
    }
  });

  cron.schedule('30 3 * * *', async () => {
    try {
      const result = await runCleanup();
      console.log('[SCHEDULER] cleanup', result);
    } catch (error) {
      console.error('[SCHEDULER] cleanup failed', error);
    }
  });

  console.log('[SCHEDULER] notification scheduler started');
};
