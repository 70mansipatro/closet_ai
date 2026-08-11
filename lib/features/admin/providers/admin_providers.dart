import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../data/models/admin_audit_log.dart';
import '../data/models/admin_dashboard.dart';
import '../data/models/admin_payment.dart';
import '../data/models/admin_plan.dart';
import '../data/models/admin_settings.dart';
import '../data/models/admin_subscription.dart';
import '../data/models/admin_user.dart';
import '../data/models/paginated_result.dart';
import '../data/repositories/admin_repository.dart';

final adminApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.read(adminApiClientProvider)),
);

// Dashboard
final dashboardRangeProvider = StateProvider<String?>((ref) => '30d');

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardSummary>((
  ref,
) async {
  final range = ref.watch(dashboardRangeProvider);
  return ref.read(adminRepositoryProvider).getDashboard(range: range);
});

// Users
class AdminUsersFilter {
  const AdminUsersFilter({
    this.page = 1,
    this.search,
    this.status,
    this.subscription,
    this.role,
  });

  final int page;
  final String? search;
  final String? status;
  final String? subscription;
  final String? role;

  AdminUsersFilter copyWith({
    int? page,
    String? search,
    String? status,
    String? subscription,
    String? role,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearSubscription = false,
    bool clearRole = false,
  }) {
    return AdminUsersFilter(
      page: page ?? this.page,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      subscription: clearSubscription
          ? null
          : (subscription ?? this.subscription),
      role: clearRole ? null : (role ?? this.role),
    );
  }
}

final adminUsersFilterProvider = StateProvider<AdminUsersFilter>(
  (ref) => const AdminUsersFilter(),
);

final adminUsersProvider = FutureProvider.autoDispose<PaginatedResult<AdminUser>>((
  ref,
) async {
  final filter = ref.watch(adminUsersFilterProvider);
  return ref.read(adminRepositoryProvider).getUsers(
    page: filter.page,
    search: filter.search,
    status: filter.status,
    subscription: filter.subscription,
    role: filter.role,
  );
});

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUser, String>((ref, userId) async {
      return ref.read(adminRepositoryProvider).getUserDetail(userId);
    });

// Subscriptions
class AdminSubscriptionsFilter {
  const AdminSubscriptionsFilter({this.page = 1, this.status, this.search});

  final int page;
  final String? status;
  final String? search;

  AdminSubscriptionsFilter copyWith({
    int? page,
    String? status,
    String? search,
    bool clearStatus = false,
  }) => AdminSubscriptionsFilter(
    page: page ?? this.page,
    status: clearStatus ? null : (status ?? this.status),
    search: search ?? this.search,
  );
}

final adminSubscriptionsFilterProvider = StateProvider<AdminSubscriptionsFilter>(
  (ref) => const AdminSubscriptionsFilter(),
);

final adminSubscriptionsProvider = FutureProvider.autoDispose<PaginatedResult<AdminSubscription>>(
    (ref) async {
      final filter = ref.watch(adminSubscriptionsFilterProvider);
      return ref
          .read(adminRepositoryProvider)
          .getSubscriptions(
            page: filter.page,
            status: filter.status,
            search: filter.search,
          );
    });

// Plans
final adminPlansProvider = FutureProvider.autoDispose<List<AdminPlan>>((
  ref,
) async {
  return ref.read(adminRepositoryProvider).getPlans();
});

// Payments
class AdminPaymentsFilter {
  const AdminPaymentsFilter({this.page = 1, this.status, this.search});

  final int page;
  final String? status;
  final String? search;

  AdminPaymentsFilter copyWith({
    int? page,
    String? status,
    String? search,
    bool clearStatus = false,
  }) => AdminPaymentsFilter(
    page: page ?? this.page,
    status: clearStatus ? null : (status ?? this.status),
    search: search ?? this.search,
  );
}

final adminPaymentsFilterProvider = StateProvider<AdminPaymentsFilter>(
  (ref) => const AdminPaymentsFilter(),
);

final adminPaymentsProvider = FutureProvider.autoDispose<PaginatedResult<AdminPayment>>((
  ref,
) async {
  final filter = ref.watch(adminPaymentsFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getPayments(page: filter.page, status: filter.status, search: filter.search);
});

// Revenue
final revenueRangeProvider = StateProvider<String?>((ref) => '30d');

final adminRevenueProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final range = ref.watch(revenueRangeProvider);
  return ref.read(adminRepositoryProvider).getRevenue(range: range, groupBy: 'day');
});

// Analytics
final analyticsRangeProvider = StateProvider<String?>((ref) => '30d');

final adminAnalyticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, domain) async {
      final range = ref.watch(analyticsRangeProvider);
      return ref.read(adminRepositoryProvider).getAnalytics(domain, range: range);
    });

// Audit logs
class AdminAuditLogsFilter {
  const AdminAuditLogsFilter({this.page = 1, this.action});

  final int page;
  final String? action;

  AdminAuditLogsFilter copyWith({int? page, String? action, bool clearAction = false}) =>
      AdminAuditLogsFilter(
        page: page ?? this.page,
        action: clearAction ? null : (action ?? this.action),
      );
}

final adminAuditLogsFilterProvider = StateProvider<AdminAuditLogsFilter>(
  (ref) => const AdminAuditLogsFilter(),
);

final adminAuditLogsProvider = FutureProvider.autoDispose<PaginatedResult<AdminAuditLog>>((
  ref,
) async {
  final filter = ref.watch(adminAuditLogsFilterProvider);
  return ref
      .read(adminRepositoryProvider)
      .getAuditLogs(page: filter.page, action: filter.action);
});

// Settings
final adminSettingsProvider = FutureProvider.autoDispose<AdminSettings>((
  ref,
) async {
  return ref.read(adminRepositoryProvider).getSettings();
});
