import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FeatureCard(
            title: 'Today’s outfit',
            subtitle: 'Smart recommendation ready',
          ),
          _FeatureCard(
            title: 'Laundry reminder',
            subtitle: '3 items need attention',
          ),
          _FeatureCard(
            title: 'Packing list',
            subtitle: 'Weekend trip prepared',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
