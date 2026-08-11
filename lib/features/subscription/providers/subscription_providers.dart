import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/subscription/data/models/payment_order.dart';
import 'package:closet_ai/features/subscription/data/models/payment_verification.dart';
import 'package:closet_ai/features/subscription/data/models/subscription.dart';
import 'package:closet_ai/features/subscription/data/models/subscription_plan.dart';
import 'package:closet_ai/features/subscription/data/repositories/subscription_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.read(apiClientProvider)),
);

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((
  ref,
) async {
  return ref.read(subscriptionRepositoryProvider).getPlans();
});

final currentSubscriptionProvider = FutureProvider<SubscriptionStatusModel>((
  ref,
) async {
  return ref.read(subscriptionRepositoryProvider).getCurrentSubscription();
});

final subscriptionStatusProvider =
    StateNotifierProvider<
      SubscriptionStatusController,
      AsyncValue<SubscriptionStatusModel>
    >(
      (ref) => SubscriptionStatusController(
        ref.read(subscriptionRepositoryProvider),
      ),
    );

final subscriptionPaymentProvider =
    StateNotifierProvider<
      SubscriptionPaymentController,
      AsyncValue<PaymentOrder?>
    >(
      (ref) => SubscriptionPaymentController(
        ref.read(subscriptionRepositoryProvider),
      ),
    );

class SubscriptionStatusController
    extends StateNotifier<AsyncValue<SubscriptionStatusModel>> {
  SubscriptionStatusController(this._repository)
    : super(const AsyncValue.loading());

  final SubscriptionRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCurrentSubscription());
  }
}

class SubscriptionPaymentController
    extends StateNotifier<AsyncValue<PaymentOrder?>> {
  SubscriptionPaymentController(this._repository)
    : super(const AsyncValue.loading());

  final SubscriptionRepository _repository;

  Future<PaymentVerification> verify({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planCode,
  }) async {
    state = const AsyncValue.loading();
    final verification = await _repository.verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      planCode: planCode,
    );
    state = AsyncValue.data(null);
    return verification;
  }
}
