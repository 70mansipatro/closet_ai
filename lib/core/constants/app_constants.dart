import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'ClosetAI';
  static const String apiBaseUrl = 'http://127.0.0.1:3000/api';
  static const String supportEmail = 'support@closetai.app';

  static String resolveApiBaseUrl({bool? isWeb, bool? isAndroid}) {
    final useWeb = isWeb ?? kIsWeb;
    if (useWeb) {
      return 'http://localhost:3000/api';
    }

    final useAndroid =
        isAndroid ?? defaultTargetPlatform == TargetPlatform.android;
    if (useAndroid) {
      return 'http://10.0.2.2:3000/api';
    }

    return apiBaseUrl;
  }
}
