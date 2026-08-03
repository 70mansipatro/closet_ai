import 'package:flutter/material.dart';

class PackingPage extends StatelessWidget {
  const PackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packing Lists')),
      body: const Center(child: Text('Smart packing suggestions go here.')),
    );
  }
}
