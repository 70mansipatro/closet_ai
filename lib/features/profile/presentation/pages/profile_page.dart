import 'package:closet_ai/features/admin/providers/admin_access_provider.dart';
import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Subscription'),
              subtitle: subscriptionAsync.when(
                data: (subscription) => Text(
                  subscription.status == 'active'
                      ? 'Premium Active'
                      : 'Free Plan',
                ),
                loading: () => const Text('Loading...'),
                error: (error, stack) => const Text('Unavailable'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/subscription'),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Panel'),
                subtitle: const Text('Manage users, plans, and analytics'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin/dashboard'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_outlined),
                  title: const Text('Reminders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: const Text('Smart Reminders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/smart-reminders'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Notification Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Account settings and preferences will appear here.'),
        ],
      ),
    );
  }
}
