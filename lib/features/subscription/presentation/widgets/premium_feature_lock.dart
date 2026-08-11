import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumFeatureLock extends StatelessWidget {
  const PremiumFeatureLock({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(
          onPressed: () => context.go('/subscription'),
          child: const Text('Upgrade'),
        ),
      ),
    );
  }
}
