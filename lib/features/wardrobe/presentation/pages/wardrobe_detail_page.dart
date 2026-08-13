import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../../widgets/section_card.dart';
import '../../../history/data/history_repository.dart';
import '../../application/wardrobe_state.dart';
import '../../data/wardrobe_repository.dart';
import '../../domain/wardrobe_item.dart';
import '../../domain/wear_history_entry.dart';
import '../widgets/mark_as_worn_sheet.dart';
import '../widgets/platform_image_preview.dart';

class ClothingDetailPage extends ConsumerStatefulWidget {
  const ClothingDetailPage({super.key, required this.itemId, this.initialItem});

  final String itemId;
  final WardrobeItem? initialItem;

  @override
  ConsumerState<ClothingDetailPage> createState() => _ClothingDetailPageState();
}

class _ClothingDetailPageState extends ConsumerState<ClothingDetailPage> {
  WardrobeItem? _item;
  List<WearHistoryEntry> _history = const [];
  bool _isLoadingItem = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  final _dateFormat = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _loadItem();
    _loadHistory();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoadingItem = _item == null;
      _errorMessage = null;
    });
    try {
      final response = await WardrobeRepository().fetchItem(widget.itemId);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _item = WardrobeItem.fromJson(data);
        _isLoadingItem = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingItem = false;
        _errorMessage = _item == null
            ? 'We could not load this item. Please try again.'
            : _errorMessage;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final repo = HistoryRepository(ApiClient());
      final response = await repo.clothingHistory(widget.itemId);
      final list = response['data'] as List<dynamic>? ?? [];
      final entries = list
          .map(
            (entry) =>
                WearHistoryEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList()
        ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
      if (!mounted) return;
      setState(() {
        _history = entries;
        _isLoadingHistory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  // Every field the item currently has must be resent on every update — the
  // backend rebuilds the full document from this payload (see
  // buildClothingPayload), so omitting a field here would silently wipe it
  // (e.g. a favorite toggle would otherwise erase style/occasions/etc).
  Map<String, dynamic> _basePayload(WardrobeItem item) => {
    'name': item.name,
    'category': item.category,
    'subCategory': item.subCategory,
    'color': item.color,
    'secondaryColors': jsonEncode(item.secondaryColors),
    'pattern': item.pattern,
    'material': item.material,
    'style': item.style,
    'season': item.season,
    'occasion': item.occasion,
    'occasions': jsonEncode(item.occasions),
    'weatherSuitability': jsonEncode(item.weatherSuitability),
    'fit': item.fit,
    'brand': item.brand,
    'size': item.size,
    'purchasePrice': item.purchasePrice,
    if (item.purchaseDate != null) 'purchaseDate': item.purchaseDate,
    'favorite': item.favorite,
    'laundryStatus': item.laundryStatus,
    'notes': item.notes,
    'aiAnalyzed': item.aiAnalyzed,
    if (item.aiAnalyzed) 'aiConfidence': jsonEncode(item.aiConfidence),
  };

  Future<void> _toggleFavorite() async {
    final item = _item;
    if (item == null) return;
    final nextFavorite = !item.favorite;
    final payload = _basePayload(item)..['favorite'] = nextFavorite;
    try {
      await ref
          .read(wardrobeControllerProvider.notifier)
          .updateItem(item.id, payload);
      if (!mounted) return;
      setState(() {
        _item = WardrobeItem.fromJson({
          ...item.toJson(),
          'favorite': nextFavorite,
        });
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite status.')),
      );
    }
  }

  Future<void> _markAsWorn() async {
    final item = _item;
    if (item == null) return;
    final result = await showMarkAsWornSheet(context, itemId: item.id);
    if (result == null || !mounted) return;
    setState(() => _item = result.item);
    await _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wear saved! Your wardrobe stats are up to date.')),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete clothing item?'),
        content: const Text(
          'This permanently removes this item and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(wardrobeControllerProvider.notifier)
          .deleteItem(widget.itemId);
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this item. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _item;

    return Scaffold(
      appBar: AppBar(title: const Text('Clothing Detail')),
      body: item == null
          ? (_isLoadingItem
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage ?? 'Item not found'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadItem,
                          icon: const Icon(Icons.refresh_outlined),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ))
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadItem(), _loadHistory()]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: item.imageUrl.isNotEmpty
                        ? PlatformImagePreview(
                            imageUrl: item.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              height: 300,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, size: 48),
                              ),
                            ),
                          )
                        : Container(
                            height: 300,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: Icon(Icons.image_outlined, size: 56)),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.aiAnalyzed) ...[
                              const SizedBox(height: 2),
                              Text(
                                '✨ Analyzed by ClosetAI',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          item.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: item.favorite ? AppColors.pink : null,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'Color', value: item.color.isEmpty ? 'Not set' : item.color),
                        _InfoChip(label: 'Pattern', value: item.pattern.isEmpty ? 'Not set' : item.pattern),
                        _InfoChip(label: 'Material', value: item.material.isEmpty ? 'Not set' : item.material),
                        _InfoChip(label: 'Style', value: item.style.isEmpty ? 'Not set' : item.style),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Usage',
                    icon: Icons.wb_sunny_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'Season', value: item.season),
                        _InfoChip(
                          label: 'Occasion',
                          value: item.occasions.isNotEmpty ? item.occasions.join(', ') : (item.occasion.isEmpty ? 'Not set' : item.occasion),
                        ),
                        _InfoChip(
                          label: 'Weather',
                          value: item.weatherSuitability.isNotEmpty ? item.weatherSuitability.join(', ') : 'Not set',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Wardrobe',
                    icon: Icons.checkroom_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'Size', value: item.size.isEmpty ? 'Not set' : item.size),
                        _InfoChip(label: 'Fit', value: item.fit.isEmpty ? 'Not set' : item.fit),
                        _InfoChip(label: 'Brand', value: item.brand.isEmpty ? 'Not set' : item.brand),
                        _InfoChip(label: 'Laundry', value: item.laundryStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Wear Statistics',
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.checkroom_rounded,
                            label: 'Wear Count',
                            value: item.wearCount.toString(),
                          ),
                        ),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.event_outlined,
                            label: 'Last Worn',
                            value: item.lastWorn != null && item.lastWorn!.isNotEmpty
                                ? _dateFormat.format(
                                    DateTime.tryParse(item.lastWorn!)?.toLocal() ??
                                        DateTime.now(),
                                  )
                                : 'Not set',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SectionCard(title: 'Notes', child: Text(item.notes)),
                  ],
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Wear History',
                    child: _isLoadingHistory && _history.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _history.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No wear history yet',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : Column(
                            children: _history
                                .map((entry) => _WearHistoryTile(entry: entry, dateFormat: _dateFormat))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/wardrobe/form', extra: item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: 'Mark as Worn',
                    icon: Icons.checkroom_rounded,
                    variant: GradientButtonVariant.success,
                    onPressed: _markAsWorn,
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WearHistoryTile extends StatelessWidget {
  const _WearHistoryTile({required this.entry, required this.dateFormat});

  final WearHistoryEntry entry;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppGradients.blueViolet,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.date != null ? dateFormat.format(entry.date!.toLocal()) : 'Unknown date',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (entry.occasion.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(entry.occasion),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
                if (entry.rating != null && entry.rating! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < entry.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 16,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
                if (entry.weather.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Weather: ${entry.weather}', style: theme.textTheme.bodySmall),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"${entry.notes}"', style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
