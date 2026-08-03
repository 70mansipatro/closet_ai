import 'package:flutter/material.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: const Center(
        child: Text('Premium features and billing will be managed here.'),
      ),
    );
  }
}
