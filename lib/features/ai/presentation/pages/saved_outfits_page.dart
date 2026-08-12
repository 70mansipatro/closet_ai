import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:flutter/material.dart';

class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key, this.repository});

  final OutfitRepository? repository;

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
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
      final response = await _repository.fetchOutfits(favorite: false);
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
        _error = 'We could not load your saved outfits.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String id, bool favorite) async {
    try {
      await _repository.toggleFavorite(id, favorite: favorite);
      await _loadOutfits();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Outfits')),
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
                    'No saved outfits yet.',
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
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppGradients.blueViolet,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        outfit['top'] ?? outfit['occasion'] ?? 'Outfit',
                      ),
                      subtitle: Text(
                        '${outfit['bottom'] ?? '—'} • ${outfit['footwear'] ?? '—'}',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          outfit['favorite'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: outfit['favorite'] == true
                              ? AppColors.pink
                              : null,
                        ),
                        onPressed: () => _toggleFavorite(
                          outfit['_id'].toString(),
                          outfit['favorite'] != true,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
