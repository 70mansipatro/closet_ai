import 'package:closet_ai/core/services/api_client.dart';

import '../models/admin_audit_log.dart';
import '../models/admin_dashboard.dart';
import '../models/admin_payment.dart';
import '../models/admin_plan.dart';
import '../models/admin_settings.dart';
import '../models/admin_subscription.dart';
import '../models/admin_user.dart';
import '../models/paginated_result.dart';

class AdminRepository {
  AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      Map<String, dynamic>.from(response['data'] as Map? ?? {});

  Map<String, dynamic> _query(Map<String, dynamic> raw) {
    final query = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value != null && value != '') query[key] = value;
    });
    return query;
  }

  // Dashboard
  Future<AdminDashboardSummary> getDashboard({String? range}) async {
    final response = await _apiClient.getWithQuery(
      '/admin/dashboard',
      query: _query({'range': range}),
    );
    return AdminDashboardSummary.fromJson(_data(response));
  }

  // Users
  Future<PaginatedResult<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? subscription,
    String? role,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/users',
      query: _query({
        'page': page,
        'limit': limit,
        'search': search,
        'status': status,
        'subscription': subscription,
        'role': role,
      }),
    );
    return PaginatedResult.fromJson(_data(response), AdminUser.fromJson);
  }

  Future<AdminUser> getUserDetail(String userId) async {
    final response = await _apiClient.get('/admin/users/$userId');
    return AdminUser.fromJson(_data(response));
  }

  Future<AdminUser> updateUserStatus(String userId, String status) async {
    final response = await _apiClient.patch(
      '/admin/users/$userId/status',
      data: {'status': status},
    );
    return AdminUser.fromJson(_data(response));
  }

  Future<AdminUser> updateUserRole(String userId, String role) async {
    final response = await _apiClient.patch(
      '/admin/users/$userId/role',
      data: {'role': role},
    );
    return AdminUser.fromJson(_data(response));
  }

  Future<void> deleteUser(String userId) async {
    await _apiClient.delete('/admin/users/$userId');
  }

  // Subscriptions
  Future<PaginatedResult<AdminSubscription>> getSubscriptions({
    int page = 1,
    int limit = 20,
    String? status,
    String? plan,
    String? search,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/subscriptions',
      query: _query({
        'page': page,
        'limit': limit,
        'status': status,
        'plan': plan,
        'search': search,
      }),
    );
    return PaginatedResult.fromJson(
      _data(response),
      AdminSubscription.fromJson,
    );
  }

  Future<AdminSubscription> getSubscriptionDetail(String id) async {
    final response = await _apiClient.get('/admin/subscriptions/$id');
    return AdminSubscription.fromJson(_data(response));
  }

  // Plans
  Future<List<AdminPlan>> getPlans() async {
    final response = await _apiClient.get('/admin/plans');
    final list = response['data'] as List? ?? const [];
    return list
        .map((item) => AdminPlan.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<AdminPlan> createPlan(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/admin/plans', data: payload);
    return AdminPlan.fromJson(_data(response));
  }

  Future<AdminPlan> updatePlan(String id, Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/admin/plans/$id', data: payload);
    return AdminPlan.fromJson(_data(response));
  }

  Future<AdminPlan> setPlanStatus(String id, bool isActive) async {
    final response = await _apiClient.patch(
      '/admin/plans/$id/status',
      data: {'isActive': isActive},
    );
    return AdminPlan.fromJson(_data(response));
  }

  // Payments
  Future<PaginatedResult<AdminPayment>> getPayments({
    int page = 1,
    int limit = 20,
    String? status,
    String? provider,
    String? search,
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/payments',
      query: _query({
        'page': page,
        'limit': limit,
        'status': status,
        'provider': provider,
        'search': search,
        'from': from,
        'to': to,
      }),
    );
    return PaginatedResult.fromJson(_data(response), AdminPayment.fromJson);
  }

  Future<AdminPayment> getPaymentDetail(String id) async {
    final response = await _apiClient.get('/admin/payments/$id');
    return AdminPayment.fromJson(_data(response));
  }

  // Revenue
  Future<Map<String, dynamic>> getRevenue({
    String? range,
    String? from,
    String? to,
    String? groupBy,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/revenue',
      query: _query({'range': range, 'from': from, 'to': to, 'groupBy': groupBy}),
    );
    return _data(response);
  }

  // Analytics — each returns the raw JSON map; shapes vary by domain.
  Future<Map<String, dynamic>> getAnalytics(
    String domain, {
    String? range,
    String? from,
    String? to,
    String? groupBy,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/analytics/$domain',
      query: _query({'range': range, 'from': from, 'to': to, 'groupBy': groupBy}),
    );
    return _data(response);
  }

  // Reports
  Future<List<String>> getReportTypes() async {
    final response = await _apiClient.get('/admin/reports');
    return (response['data'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<int>> exportReport({
    required String type,
    String format = 'csv',
    String? from,
    String? to,
    String? status,
    String? plan,
    String? role,
  }) async {
    final payload = <String, dynamic>{'type': type, 'format': format};
    if (from != null) payload['from'] = from;
    if (to != null) payload['to'] = to;
    if (status != null) payload['status'] = status;
    if (plan != null) payload['plan'] = plan;
    if (role != null) payload['role'] = role;

    return _apiClient.postForBytes('/admin/reports/export', data: payload);
  }

  // Audit logs
  Future<PaginatedResult<AdminAuditLog>> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? action,
    String? adminUserId,
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/admin/audit-logs',
      query: _query({
        'page': page,
        'limit': limit,
        'action': action,
        'adminUserId': adminUserId,
        'from': from,
        'to': to,
      }),
    );
    return PaginatedResult.fromJson(_data(response), AdminAuditLog.fromJson);
  }

  // Settings
  Future<AdminSettings> getSettings() async {
    final response = await _apiClient.get('/admin/settings');
    return AdminSettings.fromJson(_data(response));
  }

  Future<AdminSettings> updateSettings(AdminSettings settings) async {
    final response = await _apiClient.patch(
      '/admin/settings',
      data: settings.toJson(),
    );
    return AdminSettings.fromJson(_data(response));
  }
}
