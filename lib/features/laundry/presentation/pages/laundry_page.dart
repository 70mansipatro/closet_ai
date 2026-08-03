import 'package:flutter/material.dart';

class LaundryPage extends StatelessWidget {
  const LaundryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laundry')),
      body: const Center(
        child: Text('Laundry reminders and schedules will be managed here.'),
      ),
    );
  }
}
