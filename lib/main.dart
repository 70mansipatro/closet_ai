import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';

import 'core/config/app_router.dart';
import 'core/config/app_theme.dart';
import 'features/auth/application/auth_state.dart';
import 'features/notifications/domain/notification_model.dart';

void main() {
  runApp(const ProviderScope(child: ClosetAiApp()));
}

class ClosetAiApp extends ConsumerStatefulWidget {
  const ClosetAiApp({super.key});

  @override
  ConsumerState<ClosetAiApp> createState() => _ClosetAiAppState();
}

class _ClosetAiAppState extends ConsumerState<ClosetAiApp> {
  @override
  void initState() {
    super.initState();
    NotificationService().onNotificationTap = _handleNotificationTap;
    Future.microtask(() async {
      await initializeTimezones();
      await NotificationService().initialize();
      return ref.read(authControllerProvider.notifier).initialize();
    });
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    appRouter.go(routeForNotificationType(payload));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClosetAI',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
