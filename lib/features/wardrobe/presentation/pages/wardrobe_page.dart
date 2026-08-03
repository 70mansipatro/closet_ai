import 'package:flutter/material.dart';

class WardrobePage extends StatelessWidget {
  const WardrobePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: const [
          _WardrobeTile(label: 'Tops'),
          _WardrobeTile(label: 'Bottoms'),
          _WardrobeTile(label: 'Shoes'),
          _WardrobeTile(label: 'Accessories'),
        ],
      ),
    );
  }
}

class _WardrobeTile extends StatelessWidget {
  const _WardrobeTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
