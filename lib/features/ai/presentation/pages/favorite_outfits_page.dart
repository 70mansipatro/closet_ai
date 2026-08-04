import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:flutter/material.dart';

class FavoriteOutfitsPage extends StatefulWidget {
  const FavoriteOutfitsPage({super.key, this.repository});

  final OutfitRepository? repository;

  @override
  State<FavoriteOutfitsPage> createState() => _FavoriteOutfitsPageState();
}

class _FavoriteOutfitsPageState extends State<FavoriteOutfitsPage> {
  late final OutfitRepository _repository =
      widget.repository ?? OutfitRepository(ApiClient());
  bool _isLoading = true;
  List<Map<String, dynamic>> _outfits = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.fetchOutfits(favorite: true);
      final data = response['data'];
      if (data is List) {
        setState(() {
          _outfits = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      } else {
        throw Exception('Unexpected payload');
      }
    } catch (_) {
      setState(() {
        _error = 'We could not load your favorite outfits.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Outfits')),
      body: RefreshIndicator(
        onRefresh: _loadOutfits,
        child: _isLoading && _outfits.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _outfits.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _loadOutfits,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : _outfits.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'You have not favorite any outfit yet.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _outfits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final outfit = _outfits[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        outfit['top'] ?? outfit['occasion'] ?? 'Outfit',
                      ),
                      subtitle: Text(
                        '${outfit['bottom'] ?? '—'} • ${outfit['footwear'] ?? '—'}',
                      ),
                      trailing: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
