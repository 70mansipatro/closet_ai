import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/laundry_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

class LaundryPage extends ConsumerStatefulWidget {
  const LaundryPage({super.key});

  @override
  ConsumerState<LaundryPage> createState() => _LaundryPageState();
}

class _LaundryPageState extends ConsumerState<LaundryPage> {
  String? _selectedStatus;
  String? _search;
  String? _category;
  String? _season;
  String? _brand;
  final String _sortBy = 'createdAt';
  final String _sortOrder = 'desc';

  Map<String, dynamic> _params() {
    return {
      'page': 1,
      'limit': 50,
      if (_search != null && _search!.isNotEmpty) 'search': _search,
      if (_category != null && _category!.isNotEmpty) 'category': _category,
      if (_season != null && _season!.isNotEmpty) 'season': _season,
      if (_brand != null && _brand!.isNotEmpty) 'brand': _brand,
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty)
        'laundryStatus': _selectedStatus,
      'sortBy': _sortBy,
      'sortOrder': _sortOrder,
    };
  }

  Future<void> _reload() async {
    ref.invalidate(laundryItemsProvider(_params()));
    ref.invalidate(laundryStatisticsProvider);
  }

  Future<void> _setLaundryStatus(
    BuildContext context,
    Map<String, dynamic> item,
    String newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = item['id']?.toString() ?? item['_id']?.toString();
    if (id == null || id.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to identify clothing item.')),
      );
      return;
    }

    try {
      await ref.read(laundryRepositoryProvider).updateStatus(id, newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Laundry status updated to ${newStatus.toUpperCase()}'),
        ),
      );
      await _reload();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update laundry status: $error')),
      );
    }
  }

  Future<void> _showLaundryActions(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final currentStatus = item['laundryStatus']?.toString() ?? 'clean';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item['subCategory']?.toString() ??
                      item['category']?.toString() ??
                      'Laundry item',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      currentStatus,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _statusColor(
                        currentStatus,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Current status: ${currentStatus.toUpperCase()}',
                    style: TextStyle(
                      color: _statusColor(currentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _laundryStatusOptions
                      .map(
                        (status) => FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _statusColor(status),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _setLaundryStatus(context, item, status);
                          },
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<String> _laundryStatusOptions = [
    'clean',
    'ready',
    'dirty',
    'washing',
    'drying',
    'ironing',
    'in-use',
    'repair',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(laundryItemsProvider(_params()));
    final statsAsync = ref.watch(laundryStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(context),
            const SizedBox(height: 16),
            Expanded(
              child: itemsAsync.when(
                data: (data) {
                  final items =
                      (data['data'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  if (items.isEmpty) {
                    return const Center(child: Text('No laundry items found.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(items[index]);
                      final status =
                          item['laundryStatus']?.toString() ?? 'clean';
                      final statusColor = _statusColor(status);
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: statusColor, width: 4),
                          ),
                        ),
                        child: ListTile(
                          leading:
                              item['imageUrl'] != null &&
                                  item['imageUrl'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    item['imageUrl'] as String,
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: statusColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    Icons.checkroom_outlined,
                                    color: statusColor,
                                  ),
                                ),
                          title: Text(
                            item['subCategory']?.toString() ??
                                item['category']?.toString() ??
                                'Item',
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                'Laundry: $status',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showLaundryActions(context, item),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Failed to load laundry: $error')),
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => _buildStatistics(stats),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search laundry',
              prefixIcon: Icon(Icons.search_outlined),
            ),
            onChanged: (value) => _search = value.trim(),
            onSubmitted: (_) => _reload(),
          ),
        ),
        DropdownButton<String?>(
          value: _selectedStatus,
          hint: const Text('Status'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All statuses')),
            DropdownMenuItem<String?>(value: 'clean', child: Text('Clean')),
            DropdownMenuItem<String?>(value: 'ready', child: Text('Ready')),
            DropdownMenuItem<String?>(value: 'dirty', child: Text('Dirty')),
            DropdownMenuItem<String?>(value: 'washing', child: Text('Washing')),
            DropdownMenuItem<String?>(value: 'drying', child: Text('Drying')),
            DropdownMenuItem<String?>(value: 'ironing', child: Text('Ironing')),
            DropdownMenuItem<String?>(value: 'in-use', child: Text('In use')),
            DropdownMenuItem<String?>(value: 'repair', child: Text('Repair')),
          ],
          onChanged: (value) {
            setState(() => _selectedStatus = value);
            _reload();
          },
        ),
        FilledButton(onPressed: _reload, child: const Text('Apply')),
      ],
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    // A single subtle aqua/green gradient accent on the summary card, per
    // the laundry palette guidance. Individual item rows stay flat/clean.
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cyanGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatTile('Clean', stats['clean'] ?? 0),
            _buildStatTile('Dirty', stats['dirty'] ?? 0),
            _buildStatTile('Ready', stats['ready'] ?? 0),
            _buildStatTile('Due', stats['laundryDue'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, Object value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  /// Purely cosmetic mapping from laundry status to an aqua/blue/green
  /// accent color. Does not change status values or update logic.
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clean':
      case 'ready':
        return AppColors.green;
      case 'washing':
      case 'drying':
        return AppColors.cyan;
      case 'ironing':
        return AppColors.blue;
      case 'in-use':
        return AppColors.teal;
      case 'dirty':
        return AppColors.orange;
      case 'repair':
        return AppColors.error;
      default:
        return AppColors.teal;
    }
  }
}
