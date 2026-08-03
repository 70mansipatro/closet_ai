import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate outfit and packing recommendations',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask AI'),
            ),
          ],
        ),
      ),
    );
  }
}
