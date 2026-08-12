import 'package:closet_ai/features/history/data/history_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
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
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.pink,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.history_rounded,
                          color: AppColors.purple,
                        ),
                        title: Text(item['date'] ?? ''),
                        subtitle: Text(item['notes'] ?? ''),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
