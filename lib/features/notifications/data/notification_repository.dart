import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/notifications/domain/notification_model.dart';
import 'package:closet_ai/features/notifications/domain/notification_preference_model.dart';
import 'package:closet_ai/features/notifications/domain/reminder_model.dart';
import 'package:closet_ai/features/notifications/domain/smart_reminder_setting_model.dart';

class NotificationPage {
  NotificationPage({required this.items, required this.hasMore, required this.page});
  final List<NotificationModel> items;
  final bool hasMore;
  final int page;
}

class NotificationRepository {
  NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<NotificationPage> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    String? type,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/notifications',
      query: {
        'page': page,
        'limit': limit,
        if (unreadOnly) 'unreadOnly': true,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final items = _asMapList(response['data']).map(NotificationModel.fromJson).toList();
    final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
    return NotificationPage(
      items: items,
      hasMore: pagination['hasMore'] as bool? ?? false,
      page: (pagination['page'] as num?)?.toInt() ?? page,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete('/notifications/$id');
  }

  Future<void> deleteAllNotifications() async {
    await _apiClient.delete('/notifications');
  }

  Future<List<ReminderModel>> getReminders({String? type, bool? enabled}) async {
    final response = await _apiClient.getWithQuery(
      '/reminders',
      query: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (enabled != null) 'enabled': enabled,
      },
    );
    return _asMapList(response['data']).map(ReminderModel.fromJson).toList();
  }

  Future<ReminderModel> createReminder(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/reminders', data: payload);
    return ReminderModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<ReminderModel> updateReminder(String id, Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/reminders/$id', data: payload);
    return ReminderModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> deleteReminder(String id) async {
    await _apiClient.delete('/reminders/$id');
  }

  Future<ReminderModel> toggleReminder(String id) async {
    final response = await _apiClient.patch('/reminders/$id/toggle');
    return ReminderModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<ReminderModel> snoozeReminder(String id, {String? preset, int? minutes}) async {
    final response = await _apiClient.post(
      '/reminders/$id/snooze',
      data: {if (preset != null) 'preset': preset, if (minutes != null) 'minutes': minutes},
    );
    return ReminderModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<NotificationPreferenceModel> getPreferences() async {
    final response = await _apiClient.get('/notifications/preferences');
    return NotificationPreferenceModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<NotificationPreferenceModel> updatePreferences(Map<String, dynamic> changes) async {
    final response = await _apiClient.patch('/notifications/preferences', data: changes);
    return NotificationPreferenceModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<SmartReminderSettingModel> getSmartSettings() async {
    final response = await _apiClient.get('/notifications/smart-settings');
    return SmartReminderSettingModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<SmartReminderSettingModel> updateSmartSettings(Map<String, dynamic> changes) async {
    final response = await _apiClient.patch('/notifications/smart-settings', data: changes);
    return SmartReminderSettingModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
