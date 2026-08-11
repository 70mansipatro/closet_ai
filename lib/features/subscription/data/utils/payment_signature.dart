import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

String buildDemoPaymentSignature(String orderId, String paymentId) {
  final payload = '$orderId|$paymentId';
  final secret = utf8.encode('test-secret');
  final data = utf8.encode(payload);
  final digest = crypto.Hmac(crypto.sha256, secret).convert(data);
  return digest.toString();
}
