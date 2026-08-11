import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock your full wardrobe potential',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unlimited AI recommendations, advanced analytics, and premium insights.',
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/subscription'),
              child: const Text('Go Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
