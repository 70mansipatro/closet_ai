import 'package:flutter/material.dart';

class WeeklyCalendarPage extends StatelessWidget {
  const WeeklyCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: const Center(
        child: Text('Weekly calendar view - shows upcoming week.'),
      ),
    );
  }
}
