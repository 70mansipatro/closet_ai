import 'package:closet_ai/features/history/data/history_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:flutter/material.dart';

class OutfitHistoryPage extends StatefulWidget {
  final String outfitId;
  const OutfitHistoryPage({super.key, required this.outfitId});

  @override
  State<OutfitHistoryPage> createState() => _OutfitHistoryPageState();
}

class _OutfitHistoryPageState extends State<OutfitHistoryPage> {
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
      final resp = await repo.outfitHistory(widget.outfitId);
      setState(() => _items = resp['data'] ?? []);
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item['date'] ?? ''),
                  subtitle: Text(item['notes'] ?? ''),
                );
              },
            ),
    );
  }
}
