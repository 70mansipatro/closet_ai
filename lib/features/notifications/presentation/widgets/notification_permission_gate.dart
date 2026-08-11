import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:closet_ai/core/services/notification_service.dart';
import 'package:closet_ai/features/notifications/application/notification_providers.dart';

const _promptedKey = 'notification_permission_prompted';

/// Wraps the authenticated app shell. On first mount, shows a one-time soft
/// prompt asking the user to enable notifications before requesting the OS
/// permission — never blocks the app if the user declines, and never asks
/// again after the first prompt.
class NotificationPermissionGate extends ConsumerStatefulWidget {
  const NotificationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationPermissionGate> createState() => _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends ConsumerState<NotificationPermissionGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_promptedKey) ?? false;

    if (!alreadyPrompted) {
      await prefs.setBool(_promptedKey, true);
      if (!mounted) return;
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stay on top of your wardrobe'),
          content: const Text(
            'ClosetAI can remind you about outfits, laundry, trips and more.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable Notifications'),
            ),
          ],
        ),
      );

      if (shouldEnable == true) {
        await NotificationService().requestPermission();
      }
    }

    try {
      await ref.read(localNotificationSyncServiceProvider).sync();
    } catch (_) {
      // Sync failures are non-fatal; the next login/refresh will retry.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
