import 'package:flutter/material.dart';

import '../../../../core/theme/app_gradients.dart';

class WeeklyCalendarPage extends StatelessWidget {
  const WeeklyCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppGradients.blueViolet,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.view_week_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Weekly calendar view - shows upcoming week.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
