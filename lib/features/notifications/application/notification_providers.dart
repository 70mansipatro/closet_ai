import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/notifications/application/local_notification_sync_service.dart';
import 'package:closet_ai/features/notifications/data/notification_repository.dart';
import 'package:closet_ai/features/notifications/domain/notification_model.dart';
import 'package:closet_ai/features/notifications/domain/notification_preference_model.dart';
import 'package:closet_ai/features/notifications/domain/reminder_model.dart';
import 'package:closet_ai/features/notifications/domain/smart_reminder_setting_model.dart';

final notificationApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.read(notificationApiClientProvider)),
);

final localNotificationSyncServiceProvider = Provider<LocalNotificationSyncService>(
  (ref) => LocalNotificationSyncService(ref.read(notificationRepositoryProvider)),
);

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});

class NotificationListState {
  const NotificationListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filter,
    this.unreadOnly = false,
  });

  final List<NotificationModel> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? filter;
  final bool unreadOnly;

  NotificationListState copyWith({
    List<NotificationModel>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    String? filter,
    bool clearFilter = false,
    bool? unreadOnly,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filter: clearFilter ? null : (filter ?? this.filter),
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationListController extends StateNotifier<NotificationListState> {
  NotificationListController(this._repository, this._ref) : super(const NotificationListState()) {
    load();
  }

  final NotificationRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNotifications(
        page: 1,
        unreadOnly: state.unreadOnly,
        type: state.filter,
      );
      state = state.copyWith(items: result.items, page: 1, hasMore: result.hasMore, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getNotifications(
        page: nextPage,
        unreadOnly: state.unreadOnly,
        type: state.filter,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error.toString());
    }
  }

  Future<void> setFilter({String? type, bool? unreadOnly}) async {
    state = state.copyWith(
      filter: type,
      clearFilter: type == null,
      unreadOnly: unreadOnly ?? state.unreadOnly,
    );
    await load();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state = state.copyWith(
      items: state.items
          .map((n) => n.id == id
              ? NotificationModel.fromJson({
                  '_id': n.id,
                  'type': n.type,
                  'title': n.title,
                  'message': n.message,
                  'body': n.body,
                  'priority': n.priority,
                  'status': 'read',
                  'isRead': true,
                  'readAt': DateTime.now().toIso8601String(),
                  'sourceType': n.sourceType,
                  'sourceId': n.sourceId,
                  'actionType': n.actionType,
                  'actionRoute': n.actionRoute,
                  'createdAt': n.createdAt.toIso8601String(),
                })
              : n)
          .toList(),
    );
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await load();
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> delete(String id) async {
    await _repository.deleteNotification(id);
    state = state.copyWith(items: state.items.where((n) => n.id != id).toList());
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> deleteAll() async {
    await _repository.deleteAllNotifications();
    state = state.copyWith(items: []);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

final notificationListProvider =
    StateNotifierProvider.autoDispose<NotificationListController, NotificationListState>(
  (ref) => NotificationListController(ref.read(notificationRepositoryProvider), ref),
);

final remindersProvider = FutureProvider.autoDispose<List<ReminderModel>>((ref) async {
  return ref.read(notificationRepositoryProvider).getReminders();
});

class NotificationPreferencesController extends StateNotifier<AsyncValue<NotificationPreferenceModel>> {
  NotificationPreferencesController(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final NotificationRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getPreferences());
  }

  Future<void> update(Map<String, dynamic> changes) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(changes));
    }
    state = await AsyncValue.guard(() => _repository.updatePreferences(changes));
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesController, AsyncValue<NotificationPreferenceModel>>(
  (ref) => NotificationPreferencesController(ref.read(notificationRepositoryProvider)),
);

class SmartReminderSettingsController extends StateNotifier<AsyncValue<SmartReminderSettingModel>> {
  SmartReminderSettingsController(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final NotificationRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getSmartSettings());
  }

  Future<void> update(Map<String, dynamic> changes) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(changes));
    }
    state = await AsyncValue.guard(() => _repository.updateSmartSettings(changes));
  }
}

final smartReminderSettingsProvider =
    StateNotifierProvider<SmartReminderSettingsController, AsyncValue<SmartReminderSettingModel>>(
  (ref) => SmartReminderSettingsController(ref.read(notificationRepositoryProvider)),
);
