import 'package:flutter/material.dart';

class TripPage extends StatelessWidget {
  const TripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: const Center(
        child: Text('Trip planning and packing summaries will appear here.'),
      ),
    );
  }
}
