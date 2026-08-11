import 'package:flutter_test/flutter_test.dart';
import 'package:closet_ai/features/subscription/data/utils/payment_signature.dart';

void main() {
  test(
    'builds the expected demo signature for the backend verification flow',
    () {
      const orderId = 'order_123';
      const paymentId = 'pay_123';

      final signature = buildDemoPaymentSignature(orderId, paymentId);

      expect(
        signature,
        '849e7fdaf775fb6157f9e71da8e3fb39a6d995aab0814361fdfe3a1d77c11647',
      );
    },
  );
}
