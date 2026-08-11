import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionSuccessPage extends StatelessWidget {
  const SubscriptionSuccessPage({super.key, this.planName = 'Premium Monthly'});

  final String planName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Active')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Premium!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Plan: $planName'),
              const SizedBox(height: 8),
              const Text('Your subscription is now active.'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Start Exploring Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
