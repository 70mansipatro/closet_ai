import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/laundry_providers.dart';

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
                Text('Current status: ${currentStatus.toUpperCase()}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _laundryStatusOptions
                      .map(
                        (status) => FilledButton(
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
                      return ListTile(
                        leading:
                            item['imageUrl'] != null &&
                                item['imageUrl'].toString().isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  item['imageUrl'] as String,
                                ),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.checkroom_outlined),
                              ),
                        title: Text(
                          item['subCategory']?.toString() ??
                              item['category']?.toString() ??
                              'Item',
                        ),
                        subtitle: Text(
                          'Laundry: ${item['laundryStatus'] ?? 'clean'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showLaundryActions(context, item),
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
    return Card(
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
