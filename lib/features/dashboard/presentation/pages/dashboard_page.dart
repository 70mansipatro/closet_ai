import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _FeatureCard(
            title: 'Today’s outfit',
            subtitle: 'Smart recommendation ready',
          ),
          _FeatureCard(
            title: 'Analytics',
            subtitle: 'View wardrobe usage and trends',
            onTap: () => context.go('/analytics'),
          ),
          _FeatureCard(
            title: 'Laundry reminder',
            subtitle: '3 items need attention',
            onTap: () => context.go('/laundry'),
          ),
          const _FeatureCard(
            title: 'Packing list',
            subtitle: 'Weekend trip prepared',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
