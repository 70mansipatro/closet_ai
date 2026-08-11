import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/subscription/data/models/payment_order.dart';
import 'package:closet_ai/features/subscription/data/models/payment_verification.dart';
import 'package:closet_ai/features/subscription/data/models/subscription.dart';
import 'package:closet_ai/features/subscription/data/models/subscription_plan.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _apiClient.get('/subscriptions/plans');
    final list = response['data'] as List? ?? const <dynamic>[];
    return list
        .map(
          (item) =>
              SubscriptionPlan.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<SubscriptionStatusModel> getCurrentSubscription() async {
    final response = await _apiClient.get('/subscriptions/me');
    return SubscriptionStatusModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<PaymentOrder> createOrder(String planCode) async {
    final response = await _apiClient.post(
      '/subscriptions/create-order',
      data: {'planCode': planCode},
    );
    return PaymentOrder.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<PaymentVerification> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planCode,
  }) async {
    final response = await _apiClient.post(
      '/subscriptions/verify-payment',
      data: {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'planCode': planCode,
      },
    );
    return PaymentVerification.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _apiClient.post('/subscriptions/cancel');
    return Map<String, dynamic>.from(response['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> restoreSubscription() async {
    final response = await _apiClient.post('/subscriptions/restore');
    return Map<String, dynamic>.from(response['data'] as Map? ?? {});
  }

  Future<SubscriptionStatusModel> checkStatus() async {
    final response = await _apiClient.post('/subscriptions/check-status');
    return SubscriptionStatusModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}
