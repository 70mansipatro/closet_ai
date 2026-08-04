import 'package:closet_ai/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants', () {
    test('uses Android emulator host for mobile builds', () {
      expect(
        AppConstants.resolveApiBaseUrl(isWeb: false, isAndroid: true),
        'http://10.0.2.2:3000/api',
      );
    });

    test('uses localhost for web builds', () {
      expect(
        AppConstants.resolveApiBaseUrl(isWeb: true, isAndroid: false),
        'http://localhost:3000/api',
      );
    });
  });
}
