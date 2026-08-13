import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../application/wardrobe_state.dart';
import '../../domain/wardrobe_item.dart';
import '../widgets/platform_image_preview.dart';

final _cardDateFormat = DateFormat('d MMM yyyy');

Color _laundryBadgeColor(String status) {
  switch (status.toLowerCase()) {
    case 'clean':
    case 'ready':
      return AppColors.success;
    case 'dirty':
    case 'repair':
      return AppColors.error;
    default:
      return AppColors.orange;
  }
}

String _formatLastWorn(String? lastWorn) {
  if (lastWorn == null || lastWorn.isEmpty) return 'Never worn';
  final parsed = DateTime.tryParse(lastWorn);
  if (parsed == null) return 'Never worn';
  return _cardDateFormat.format(parsed.toLocal());
}

class WardrobePage extends ConsumerStatefulWidget {
  const WardrobePage({super.key});

  @override
  ConsumerState<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends ConsumerState<WardrobePage> {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  String? _selectedCategory;
  String? _selectedSeason;
  String? _selectedLaundryStatus;
  String? _brandFilter;
  bool? _favoriteFilter;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _reload());
  }

  Future<void> _reload() async {
    await ref
        .read(wardrobeControllerProvider.notifier)
        .loadItems(
          refresh: true,
          search: _searchController.text.trim(),
          category: _selectedCategory,
          season: _selectedSeason,
          brand: _brandFilter,
          laundryStatus: _selectedLaundryStatus,
          favorite: _favoriteFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wardrobeControllerProvider);
    final controller = ref.read(wardrobeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 1400
                ? 6
                : constraints.maxWidth >= 900
                ? 4
                : 2;
            final aspectRatio = constraints.maxWidth >= 900 ? 0.88 : 0.78;

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >
                        notification.metrics.maxScrollExtent - 320 &&
                    state.hasMore &&
                    !state.isLoading) {
                  controller.loadItems(
                    search: _searchController.text.trim(),
                    category: _selectedCategory,
                    season: _selectedSeason,
                    brand: _brandFilter,
                    laundryStatus: _selectedLaundryStatus,
                    favorite: _favoriteFilter,
                    sortBy: _sortBy,
                    sortOrder: _sortOrder,
                  );
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search wardrobe',
                          prefixIcon: const Icon(Icons.search_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_outlined),
                            onPressed: () {
                              _searchController.clear();
                              _reload();
                            },
                          ),
                        ),
                        onSubmitted: (_) => _reload(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterPill(
                            label: _selectedCategory == null
                                ? 'All categories'
                                : _selectedCategory!.toUpperCase(),
                            isActive: _selectedCategory != null,
                            onPressed: () => _showFilterSheet(),
                          ),
                          _FilterPill(
                            label: _selectedSeason == null
                                ? 'All seasons'
                                : _selectedSeason!.toUpperCase(),
                            isActive: _selectedSeason != null,
                            onPressed: () => _showFilterSheet(),
                          ),
                          _FilterPill(
                            label: _favoriteFilter == null
                                ? 'All favorites'
                                : (_favoriteFilter!
                                      ? 'Favorites only'
                                      : 'Non-favorites'),
                            isActive: _favoriteFilter != null,
                            onPressed: () => _showFilterSheet(),
                          ),
                          _FilterPill(
                            label: _brandFilter == null || _brandFilter!.isEmpty
                                ? 'All brands'
                                : _brandFilter!,
                            isActive:
                                _brandFilter != null && _brandFilter!.isNotEmpty,
                            onPressed: () => _showFilterSheet(),
                          ),
                          TextButton.icon(
                            onPressed: _showSortSheet,
                            icon: const Icon(Icons.sort_outlined),
                            label: const Text('Sort'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.isLoading && state.items.isEmpty)
                    const SliverToBoxAdapter(child: LoadingState())
                  else if (state.errorMessage != null && state.items.isEmpty)
                    SliverFillRemaining(
                      child: ErrorState(
                        message: state.errorMessage!,
                        onRetry: _reload,
                      ),
                    )
                  else if (state.items.isEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        onAdd: () async {
                          await context.push('/wardrobe/form');
                          await _reload();
                        },
                      ),
                    )
                  else if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = state.items[index];
                          return WardrobeCard(
                            item: item,
                            onDelete: () => controller.deleteItem(item.id),
                          );
                        }, childCount: state.items.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = state.items[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: WardrobeListTile(
                            item: item,
                            onDelete: () => controller.deleteItem(item.id),
                          ),
                        );
                      }, childCount: state.items.length),
                    ),
                  if (state.items.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      sliver: SliverToBoxAdapter(
                        child: state.hasMore
                            ? FilledButton.icon(
                                onPressed: state.isLoading
                                    ? null
                                    : () => controller.loadItems(
                                        search: _searchController.text.trim(),
                                        category: _selectedCategory,
                                        season: _selectedSeason,
                                        brand: _brandFilter,
                                        laundryStatus: _selectedLaundryStatus,
                                        favorite: _favoriteFilter,
                                        sortBy: _sortBy,
                                        sortOrder: _sortOrder,
                                      ),
                                icon: state.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more_outlined),
                                label: Text(
                                  state.isLoading ? 'Loading…' : 'Load more',
                                ),
                              )
                            : const Center(child: Text('No more items')),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _GradientFab(
        onPressed: () async {
          await context.push('/wardrobe/form');
          await _reload();
        },
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      builder: (context) => FilterSheet(
        selectedCategory: _selectedCategory,
        selectedSeason: _selectedSeason,
        selectedLaundryStatus: _selectedLaundryStatus,
        favoriteFilter: _favoriteFilter,
        brandFilter: _brandFilter,
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedCategory = result['category'] as String?;
      _selectedSeason = result['season'] as String?;
      _selectedLaundryStatus = result['laundryStatus'] as String?;
      _favoriteFilter = result['favorite'] as bool?;
      _brandFilter = result['brand'] as String?;
    });
    await _reload();
  }

  Future<void> _showSortSheet() async {
    final sort = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (context) =>
          SortSheet(currentSortBy: _sortBy, currentSortOrder: _sortOrder),
    );
    if (sort == null) return;
    setState(() {
      _sortBy = sort['sortBy']!;
      _sortOrder = sort['sortOrder']!;
    });
    await _reload();
  }
}

/// A filter pill matching the current filter-sheet trigger. When a filter
/// is actively applied (non-default), it lights up with the primary brand
/// gradient instead of the neutral themed chip.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return ActionChip(label: Text(label), onPressed: onPressed);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient-filled floating action button for the primary "Add" action.
class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Loading your wardrobe…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We could not load your wardrobe',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checkroom_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your wardrobe is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first clothing item to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_outlined),
                    label: const Text('+ Add Clothing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WardrobeCard extends StatelessWidget {
  const WardrobeCard({super.key, required this.item, required this.onDelete});

  final WardrobeItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/wardrobe/${item.id}', extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isNotEmpty
                      ? PlatformImagePreview(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 48),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: item.favorite ? AppColors.pink : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _LaundryBadge(status: item.laundryStatus),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.category.toUpperCase()} • ${item.brand.isEmpty ? 'No brand' : item.brand}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(item.color.isEmpty ? 'Mixed' : item.color),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(item.season),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.checkroom_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Worn ${item.wearCount}×', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatLastWorn(item.lastWorn),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaundryBadge extends StatelessWidget {
  const _LaundryBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _laundryBadgeColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'clean' : status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class WardrobeListTile extends StatelessWidget {
  const WardrobeListTile({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final WardrobeItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/wardrobe/${item.id}', extra: item),
        leading: item.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PlatformImagePreview(
                  imageUrl: item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: const Icon(Icons.image_not_supported_outlined),
                ),
              )
            : const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.image_outlined),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              item.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: item.favorite ? AppColors.pink : null,
            ),
          ],
        ),
        subtitle: Text(
          '${item.category.toUpperCase()} • ${item.brand.isEmpty ? 'No brand' : item.brand} • Worn ${item.wearCount}× • ${_formatLastWorn(item.lastWorn)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LaundryBadge(status: item.laundryStatus),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedSeason,
    required this.selectedLaundryStatus,
    required this.favoriteFilter,
    required this.brandFilter,
  });

  final String? selectedCategory;
  final String? selectedSeason;
  final String? selectedLaundryStatus;
  final bool? favoriteFilter;
  final String? brandFilter;

  @override
  State<FilterSheet> createState() => FilterSheetState();
}

class FilterSheetState extends State<FilterSheet> {
  late String? _category;
  late String? _season;
  late String? _laundryStatus;
  late bool? _favorite;
  late final TextEditingController _brandController;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _season = widget.selectedSeason;
    _laundryStatus = widget.selectedLaundryStatus;
    _favorite = widget.favoriteFilter;
    _brandController = TextEditingController(text: widget.brandFilter ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Favorites only'),
                    selected: _favorite == true,
                    onSelected: (_) => setState(
                      () => _favorite = _favorite == true ? null : true,
                    ),
                  ),
                  FilterChip(
                    label: const Text('All'),
                    selected: _favorite == null,
                    onSelected: (_) => setState(() => _favorite = null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'top',
                      'bottom',
                      'dress',
                      'outerwear',
                      'shoes',
                      'accessory',
                      'other',
                    ].map((value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _category == value,
                        onSelected: (_) => setState(
                          () => _category = _category == value ? null : value,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Season'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['spring', 'summer', 'autumn', 'winter', 'all-season']
                    .map((value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _season == value,
                        onSelected: (_) => setState(
                          () => _season = _season == value ? null : value,
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text('Laundry Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'clean',
                      'ready',
                      'dirty',
                      'washing',
                      'drying',
                      'ironing',
                      'in-use',
                      'repair',
                    ].map((value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _laundryStatus == value,
                        onSelected: (_) => setState(
                          () => _laundryStatus = _laundryStatus == value
                              ? null
                              : value,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop({
                  'category': _category,
                  'season': _season,
                  'laundryStatus': _laundryStatus,
                  'favorite': _favorite,
                  'brand': _brandController.text.trim(),
                }),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SortSheet extends StatelessWidget {
  const SortSheet({
    super.key,
    required this.currentSortBy,
    required this.currentSortOrder,
  });

  final String currentSortBy;
  final String currentSortOrder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Recently Added'),
                selected: currentSortBy == 'createdAt' && currentSortOrder == 'desc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'createdAt', 'sortOrder': 'desc'}),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up_outlined),
                title: const Text('Most Worn'),
                selected: currentSortBy == 'wearCount' && currentSortOrder == 'desc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'wearCount', 'sortOrder': 'desc'}),
              ),
              ListTile(
                leading: const Icon(Icons.trending_down_outlined),
                title: const Text('Least Worn'),
                selected: currentSortBy == 'wearCount' && currentSortOrder == 'asc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'wearCount', 'sortOrder': 'asc'}),
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Recently Worn'),
                selected: currentSortBy == 'lastWorn' && currentSortOrder == 'desc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'lastWorn', 'sortOrder': 'desc'}),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_outlined),
                title: const Text('Name A-Z'),
                selected: currentSortBy == 'name' && currentSortOrder == 'asc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'name', 'sortOrder': 'asc'}),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline_rounded),
                title: const Text('Favorites'),
                selected: currentSortBy == 'favorite' && currentSortOrder == 'desc',
                onTap: () => Navigator.of(
                  context,
                ).pop({'sortBy': 'favorite', 'sortOrder': 'desc'}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
