import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_state.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isLoading && authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go('/dashboard'),
      );
    } else if (!authState.isLoading && !authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go('/welcome'),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom_rounded, size: 64),
            const SizedBox(height: 16),
            Text(
              'ClosetAI',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
