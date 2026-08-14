import 'package:closet_ai/core/layout/app_layout.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:closet_ai/features/ai/presentation/widgets/outfit_status_badge.dart';
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

  Future<void> _wearAgain(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.wearOutfit(id);
      await _loadOutfits();
      messenger.showSnackBar(const SnackBar(content: Text('Outfit marked as worn.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to mark outfit as worn. Please try again.')),
      );
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomPadding(context)),
                itemCount: _outfits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final outfit = _outfits[index];
                  final id = outfit['_id'].toString();
                  final status = (outfit['status'] ?? 'saved').toString();
                  final thumbnailUrl = outfitThumbnailUrl(outfit);
                  final name = (outfit['outfitName'] as String?)?.isNotEmpty == true
                      ? outfit['outfitName'] as String
                      : (outfit['top'] ?? outfit['occasion'] ?? 'Outfit').toString();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: thumbnailUrl != null
                                    ? Image.network(
                                        thumbnailUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => fallbackOutfitThumbnail(),
                                      )
                                    : fallbackOutfitThumbnail(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(name, style: Theme.of(context).textTheme.titleSmall)),
                                        OutfitStatusBadge(status: status),
                                      ],
                                    ),
                                    Text(
                                      '${outfit['bottom'] ?? '—'} • ${outfit['footwear'] ?? '—'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite, color: AppColors.pink),
                                onPressed: () => _toggleFavorite(id, false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _wearAgain(id),
                                icon: const Icon(Icons.checkroom, size: 18),
                                label: const Text('Wear Again'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
