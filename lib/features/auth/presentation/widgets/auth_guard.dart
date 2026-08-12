import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_state.dart';

/// Wraps the authenticated app shell and redirects to /login the moment
/// [authControllerProvider] reports a logged-out session — e.g. after
/// [ApiClient.onSessionExpired] fires because a refresh-token attempt failed.
/// Mirrors AdminGuard's reactive ref.watch pattern rather than go_router's
/// static `redirect:`, so it reacts immediately to state changes instead of
/// only re-evaluating on the next navigation.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isLoading && !authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/login');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
