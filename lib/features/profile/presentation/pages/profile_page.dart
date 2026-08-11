import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);

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
          const SizedBox(height: 12),
          const Text('Account settings and preferences will appear here.'),
        ],
      ),
    );
  }
}
