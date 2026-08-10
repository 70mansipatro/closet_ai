import 'package:closet_ai/features/history/data/history_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:flutter/material.dart';

class WearHistoryPage extends StatefulWidget {
  const WearHistoryPage({super.key});

  @override
  State<WearHistoryPage> createState() => _WearHistoryPageState();
}

class _WearHistoryPageState extends State<WearHistoryPage> {
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = HistoryRepository(ApiClient());
      final resp = await repo.list();
      setState(
        () => _items = resp['data'] is Map ? resp['data']['items'] ?? [] : [],
      );
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wear History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item['notes'] ?? item['occasion'] ?? 'Wear'),
                  subtitle: Text(item['date'] ?? ''),
                );
              },
            ),
    );
  }
}
