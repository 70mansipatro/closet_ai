import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Android notification channels used across ClosetAI. Keep this list small —
/// one channel per meaningfully different importance/behavior, not per notification type.
class NotificationChannels {
  static const reminders = AndroidNotificationChannel(
    'closetai_channel',
    'ClosetAI Reminders',
    description: 'Outfit, laundry, wardrobe and wear-history reminders',
    importance: Importance.defaultImportance,
  );

  static const important = AndroidNotificationChannel(
    'closetai_important',
    'ClosetAI Important',
    description: 'High priority reminders that need timely attention',
    importance: Importance.max,
  );

  static const subscription = AndroidNotificationChannel(
    'closetai_subscription',
    'ClosetAI Subscription',
    description: 'Premium and subscription related notifications',
    importance: Importance.high,
  );

  static const trips = AndroidNotificationChannel(
    'closetai_trips',
    'ClosetAI Trips',
    description: 'Trip and packing reminders',
    importance: Importance.high,
  );

  static const all = [reminders, important, subscription, trips];
}

/// Maps a backend notification `type` to the most appropriate Android channel.
String channelIdForType(String type) {
  switch (type) {
    case 'SUBSCRIPTION_REMINDER':
    case 'PREMIUM_EXPIRY':
      return NotificationChannels.subscription.id;
    case 'TRIP_REMINDER':
    case 'PACKING_REMINDER':
      return NotificationChannels.trips.id;
    case 'ADMIN_ANNOUNCEMENT':
      return NotificationChannels.important.id;
    default:
      return NotificationChannels.reminders.id;
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the app shell to handle a tap on a (possibly backgrounded/terminated)
  /// notification. Receives the raw `payload` string set when scheduling.
  void Function(String? payload)? onNotificationTap;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in NotificationChannels.all) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Requests notification permission on Android 13+ and iOS. Safe to call
  /// multiple times — the OS only prompts once per install unless denied.
  Future<bool> requestPermission() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String channelId = 'closetai_channel',
    String? payload,
  }) async {
    final channel = NotificationChannels.all.firstWhere(
      (c) => c.id == channelId,
      orElse: () => NotificationChannels.reminders,
    );
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Schedules a single notification to fire at [dateTime]. If [dateTime] is
  /// already in the past, it fires as soon as possible instead of being dropped.
  Future<void> scheduleOneOff(
    int id,
    String title,
    String body,
    DateTime dateTime, {
    String channelId = 'closetai_channel',
    String? payload,
  }) async {
    final channel = NotificationChannels.all.firstWhere(
      (c) => c.id == channelId,
      orElse: () => NotificationChannels.reminders,
    );
    var scheduled = tz.TZDateTime.from(dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = now.add(const Duration(seconds: 5));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name),
        iOS: const DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDaily(
    int id,
    String title,
    String body,
    int hour,
    int minute, [
    int second = 0,
  ]) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute, second),
      const NotificationDetails(
        android: AndroidNotificationDetails('closetai_channel', 'ClosetAI Reminders'),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<Set<int>> pendingNotificationIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toSet();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, int second) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      second,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Deterministic local notification id derived from a stable string key
/// (e.g. a reminder's MongoDB id) so re-syncing never creates duplicate
/// scheduled notifications for the same reminder.
int localNotificationIdFor(String key) => key.hashCode & 0x7fffffff;

// Initialize timezone data before scheduling
Future<void> initializeTimezones() async {
  tzdata.initializeTimeZones();
}
