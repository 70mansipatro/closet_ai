import 'package:closet_ai/features/wardrobe/data/wardrobe_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiHomePage extends StatefulWidget {
  const AiHomePage({super.key});

  @override
  State<AiHomePage> createState() => _AiHomePageState();
}

class _AiHomePageState extends State<AiHomePage> {
  final WardrobeRepository _repository = WardrobeRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _wardrobe = const [];
  int _totalClothes = 0;
  int _cleanClothes = 0;
  int _dirtyClothes = 0;
  int _favoriteClothes = 0;
  int _todayWorn = 0;

  static const List<String> _categoryOrder = [
    'top',
    'bottom',
    'footwear',
    'watch',
    'bag',
    'outerwear',
    'accessory',
  ];

  @override
  void initState() {
    super.initState();
    _loadWardrobeSummary();
  }

  bool get _hasClothes => _wardrobe.isNotEmpty;

  bool get _canGenerate =>
      _countForCategory('top') > 0 &&
      _countForCategory('bottom') > 0 &&
      _countForCategory('footwear') > 0;

  Map<String, List<Map<String, dynamic>>> get _groupedWardrobe {
    final grouped = {
      'top': <Map<String, dynamic>>[],
      'bottom': <Map<String, dynamic>>[],
      'footwear': <Map<String, dynamic>>[],
      'watch': <Map<String, dynamic>>[],
      'bag': <Map<String, dynamic>>[],
      'outerwear': <Map<String, dynamic>>[],
      'accessory': <Map<String, dynamic>>[],
    };

    for (final item in _wardrobe) {
      final category = _normalizeCategory((item['category'] ?? '').toString());
      final target = _mapCategoryToChecklistKey(category);
      if (target == null) {
        continue;
      }
      grouped[target]!.add(item);
    }

    return grouped;
  }

  int _countForCategory(String key) =>
      (_groupedWardrobe[key] ?? const []).length;

  String _normalizeCategory(String value) => value.trim().toLowerCase();

  String? _mapCategoryToChecklistKey(String category) {
    final normalized = _normalizeCategory(category);
    if (normalized == 'top' || normalized == 'tops') return 'top';
    if (normalized == 'bottom' || normalized == 'bottoms') return 'bottom';
    if (normalized == 'shoe' ||
        normalized == 'shoes' ||
        normalized == 'footwear') {
      return 'footwear';
    }
    if (normalized == 'watch' || normalized == 'watches') return 'watch';
    if (normalized == 'bag' || normalized == 'bags') return 'bag';
    if (normalized == 'outerwear' ||
        normalized == 'jacket' ||
        normalized == 'coat') {
      return 'outerwear';
    }
    if (normalized == 'accessory' ||
        normalized == 'accessories' ||
        normalized == 'other') {
      return 'accessory';
    }
    return null;
  }

  String _titleForCategory(String key) {
    switch (key) {
      case 'top':
        return 'TOPS';
      case 'bottom':
        return 'BOTTOMS';
      case 'footwear':
        return 'FOOTWEAR';
      case 'watch':
        return 'WATCH';
      case 'bag':
        return 'BAG';
      case 'outerwear':
        return 'OUTERWEAR';
      case 'accessory':
        return 'ACCESSORIES';
      default:
        return key.toUpperCase();
    }
  }

  String _itemLabelForCategory(String key) {
    switch (key) {
      case 'top':
        return 'Shirts';
      case 'bottom':
        return 'Jeans';
      case 'footwear':
        return 'Shoes';
      case 'watch':
        return 'Watch';
      case 'bag':
        return 'Bag';
      case 'outerwear':
        return 'Jacket';
      case 'accessory':
        return 'Accessories';
      default:
        return 'Items';
    }
  }

  String _addLabelForCategory(String key) {
    switch (key) {
      case 'top':
        return 'Shirt';
      case 'bottom':
        return 'Jeans';
      case 'footwear':
        return 'Shoes';
      case 'watch':
        return 'Watch';
      case 'bag':
        return 'Bag';
      case 'outerwear':
        return 'Jacket';
      case 'accessory':
        return 'Accessories';
      default:
        return 'Item';
    }
  }

  String _statusTextForCategory(String key, int count) {
    final label = _itemLabelForCategory(key);
    return count > 0 ? '$label ($count) ✅' : '$label ➕';
  }

  Future<void> _loadWardrobeSummary() async {
    try {
      final response = await _repository.fetchItems(page: 1, limit: 200);
      final data = response['data'];
      if (data is! List) {
        setState(() {
          _isLoading = false;
          _wardrobe = const [];
        });
        return;
      }

      final wardrobe = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      int cleanClothes = 0;
      int dirtyClothes = 0;
      int favorite = 0;
      int todayWorn = 0;
      final now = DateTime.now();

      for (final item in wardrobe) {
        final laundryStatus = (item['laundryStatus'] ?? '')
            .toString()
            .toLowerCase();
        final isDirty = laundryStatus == 'dirty';
        final isFavorite = item['favorite'] == true;
        final lastWorn = item['lastWorn'];

        if (isDirty) {
          dirtyClothes += 1;
        } else {
          cleanClothes += 1;
        }

        if (isFavorite) {
          favorite += 1;
        }

        if (lastWorn != null && lastWorn.toString().isNotEmpty) {
          final parsedDate = DateTime.tryParse(lastWorn.toString());
          if (parsedDate != null &&
              parsedDate.year == now.year &&
              parsedDate.month == now.month &&
              parsedDate.day == now.day) {
            todayWorn += 1;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _wardrobe = wardrobe;
        _totalClothes = wardrobe.length;
        _cleanClothes = cleanClothes;
        _dirtyClothes = dirtyClothes;
        _favoriteClothes = favorite;
        _todayWorn = todayWorn;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAddCloth(String key) {
    final normalized = _normalizeCategory(key);
    String category = 'top';
    if (normalized == 'bottom' || normalized == 'bottoms') {
      category = 'bottom';
    } else if (normalized == 'shoe' ||
        normalized == 'shoes' ||
        normalized == 'footwear') {
      category = 'shoes';
    } else if (normalized == 'watch' || normalized == 'watches') {
      category = 'other';
    } else if (normalized == 'bag' || normalized == 'bags') {
      category = 'other';
    } else if (normalized == 'outerwear' ||
        normalized == 'jacket' ||
        normalized == 'coat') {
      category = 'outerwear';
    } else if (normalized == 'accessory' || normalized == 'accessories') {
      category = 'accessory';
    }

    context.push('/wardrobe/form', extra: {'category': category});
  }

  void _openGenerate() {
    if (!_canGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one Top, Bottom and Footwear before generating an outfit.',
          ),
        ),
      );
      return;
    }
    context.go('/ai/generate');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedWardrobe;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Outfit Studio')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Home', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Generate recommendations from your wardrobe and keep your outfit plan ready for the week.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (!_hasClothes)
                      _EmptyStateCard(
                        onAddFirstCloth: () => _openAddCloth('top'),
                      )
                    else ...[
                      _SummaryCard(
                        total: _totalClothes,
                        clean: _cleanClothes,
                        dirty: _dirtyClothes,
                        favorite: _favoriteClothes,
                        todayWorn: _todayWorn,
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Wardrobe Checklist',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _canGenerate ? 'Ready' : 'Needs items',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._categoryOrder.map((key) {
                                final items = grouped[key] ?? const [];
                                final count = items.length;
                                final filled = count > 0;
                                final label = _titleForCategory(key);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              label,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              filled
                                                  ? Icons.check_circle
                                                  : Icons.add_circle_outline,
                                              color: filled
                                                  ? Colors.green.shade700
                                                  : theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              filled ? 'Filled' : 'Missing',
                                              style:
                                                  theme.textTheme.labelMedium,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              filled ? Icons.check : Icons.add,
                                              size: 18,
                                              color: filled
                                                  ? Colors.green.shade700
                                                  : theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _statusTextForCategory(
                                                  key,
                                                  count,
                                                ),
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _openAddCloth(key),
                                              icon: const Icon(Icons.add),
                                              label: Text(
                                                '+ Add ${_addLabelForCategory(key)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outfit Generator',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _canGenerate ? _openGenerate : null,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate Outfit'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/ai/stylist'),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Open AI Stylist'),
                            ),
                            if (!_canGenerate)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Please add at least one Top, Bottom and Footwear before generating an outfit.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.clean,
    required this.dirty,
    required this.favorite,
    required this.todayWorn,
  });

  final int total;
  final int clean;
  final int dirty;
  final int favorite;
  final int todayWorn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      _StatTile(label: 'Total Clothes', value: total.toString()),
      _StatTile(label: 'Clean Clothes', value: clean.toString()),
      _StatTile(label: 'Dirty Clothes', value: dirty.toString()),
      _StatTile(label: 'Favorite Clothes', value: favorite.toString()),
      _StatTile(label: "Today's Worn", value: todayWorn.toString()),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wardrobe Summary', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.9,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) => stats[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onAddFirstCloth});

  final VoidCallback onAddFirstCloth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checkroom_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No clothes added yet',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your first item to start building a wardrobe for outfit recommendations.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddFirstCloth,
                icon: const Icon(Icons.add),
                label: const Text('Add First Cloth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
