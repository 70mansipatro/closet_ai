import 'package:closet_ai/features/history/data/history_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/core/layout/app_layout.dart';
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
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppLayout.scrollBottomPadding(context),
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isMostRecent = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isMostRecent
                              ? AppGradients.premium
                              : AppGradients.blueViolet,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(item['notes'] ?? item['occasion'] ?? 'Wear'),
                      subtitle: Text(item['date'] ?? ''),
                      trailing: isMostRecent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppGradients.premium,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Latest',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
