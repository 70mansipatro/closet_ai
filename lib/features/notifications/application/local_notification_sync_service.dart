import 'package:closet_ai/core/services/notification_service.dart';
import 'package:closet_ai/features/notifications/data/notification_repository.dart';
import 'package:closet_ai/features/notifications/domain/notification_preference_model.dart';
import 'package:closet_ai/features/notifications/domain/reminder_model.dart';

/// Pulls enabled reminders + preferences from the backend and mirrors them as
/// device-local scheduled notifications, so reminders still fire while the
/// app is closed. Uses a deterministic notification id per reminder
/// (see [localNotificationIdFor]) so repeated syncs never create duplicates.
class LocalNotificationSyncService {
  LocalNotificationSyncService(this._repository, {NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationRepository _repository;
  final NotificationService _notificationService;

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return h * 60 + m;
  }

  DateTime _adjustForQuietHours(DateTime dateTime, NotificationPreferenceModel prefs, String priority) {
    if (!prefs.quietHoursEnabled || priority == 'urgent') return dateTime;

    final minutesOfDay = dateTime.hour * 60 + dateTime.minute;
    final start = _toMinutes(prefs.quietHoursStart);
    final end = _toMinutes(prefs.quietHoursEnd);

    final inQuietHours = start <= end
        ? (minutesOfDay >= start && minutesOfDay < end)
        : (minutesOfDay >= start || minutesOfDay < end);
    if (!inQuietHours) return dateTime;

    final endHour = end ~/ 60;
    final endMinute = end % 60;
    var adjusted = DateTime(dateTime.year, dateTime.month, dateTime.day, endHour, endMinute);
    if (adjusted.isBefore(dateTime)) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }

  /// Fetches reminders + preferences and reconciles device-local schedules.
  /// Safe to call repeatedly (login, pull-to-refresh, after any reminder edit).
  Future<void> sync() async {
    final preferences = await _repository.getPreferences();
    if (!preferences.localEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    final reminders = await _repository.getReminders(enabled: true);
    final now = DateTime.now();

    final activeIds = <int>{};
    for (final ReminderModel reminder in reminders) {
      if (reminder.nextTriggerAt == null) continue;
      if (reminder.nextTriggerAt!.isBefore(now)) continue;
      if (!_isReminderCategoryEnabled(reminder, preferences)) continue;

      final id = localNotificationIdFor(reminder.id);
      activeIds.add(id);
      final triggerAt = _adjustForQuietHours(reminder.nextTriggerAt!, preferences, reminder.priority);

      await _notificationService.scheduleOneOff(
        id,
        reminder.title,
        reminder.description.isNotEmpty ? reminder.description : reminder.title,
        triggerAt,
        channelId: channelIdForType(reminder.type),
        payload: reminder.type,
      );
    }

    final pendingIds = await _notificationService.pendingNotificationIds();
    for (final pendingId in pendingIds) {
      if (!activeIds.contains(pendingId)) {
        await _notificationService.cancel(pendingId);
      }
    }
  }

  bool _isReminderCategoryEnabled(ReminderModel reminder, NotificationPreferenceModel prefs) {
    switch (reminder.type) {
      case 'OUTFIT_REMINDER':
        return prefs.outfitReminders;
      case 'LAUNDRY_REMINDER':
        return prefs.laundryReminders;
      case 'TRIP_REMINDER':
        return prefs.tripReminders;
      case 'PACKING_REMINDER':
        return prefs.packingReminders;
      case 'WEAR_HISTORY_REMINDER':
        return prefs.wearHistoryReminders;
      case 'WARDROBE_REMINDER':
        return prefs.wardrobeReminders;
      case 'AI_STYLIST_REMINDER':
        return prefs.aiStylistReminders;
      case 'SUBSCRIPTION_REMINDER':
        return prefs.subscriptionReminders;
      default:
        return true;
    }
  }
}
