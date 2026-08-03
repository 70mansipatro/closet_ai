import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_router.dart';
import 'core/config/app_theme.dart';
import 'features/auth/application/auth_state.dart';

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
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClosetAI',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
