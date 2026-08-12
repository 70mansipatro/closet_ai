import 'package:closet_ai/features/packing/application/packing_providers.dart';
import 'package:closet_ai/features/packing/domain/packing_item.dart';
import 'package:closet_ai/features/trip/application/trip_providers.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PackingPage extends ConsumerStatefulWidget {
  const PackingPage({super.key, this.tripId});

  final String? tripId;

  @override
  ConsumerState<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends ConsumerState<PackingPage> {
  String? _selectedTripId;
  String? _packingSummary;
  List<String> _packingTips = [];

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.tripId;
  }

  @override
  void didUpdateWidget(covariant PackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tripId != oldWidget.tripId) {
      setState(() {
        _selectedTripId = widget.tripId;
        _packingSummary = null;
        _packingTips = [];
      });
    }
  }

  Future<void> _generatePacking() async {
    if (_selectedTripId == null) {
      return;
    }

    try {
      final response = await ref
          .read(packingRepositoryProvider)
          .generatePacking(_selectedTripId!);
      setState(() {
        _packingSummary =
            response['data']?['summary'] as String? ?? 'Packing list generated';
        _packingTips =
            (response['data']?['tips'] as List<dynamic>?)
                ?.map((tip) => tip.toString())
                .toList() ??
            [];
      });
      ref.invalidate(packingListProvider(_selectedTripId!));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate packing: $error')),
      );
    }
  }

  Widget _buildPackingItem(PackingItem item) {
    Future<void> toggle() async {
      if (_selectedTripId == null) return;
      await ref
          .read(packingRepositoryProvider)
          .togglePacked(_selectedTripId!, item.id);
      ref.invalidate(packingListProvider(_selectedTripId!));
    }

    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${item.category} · Qty ${item.quantity}${item.reason.isNotEmpty ? ' · ${item.reason}' : ''}',
        ),
        trailing: GestureDetector(
          onTap: toggle,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: item.packed ? AppGradients.primary : null,
              borderRadius: BorderRadius.circular(8),
              border: item.packed
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
            ),
            child: item.packed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }

  /// Custom gradient-filled progress bar for the packing checklist. Reads
  /// the already-fetched item list purely to compute a display fraction —
  /// it does not alter how packed/total is calculated elsewhere.
  Widget _buildPackingProgress(List<PackingItem> items) {
    final total = items.length;
    final packed = items.where((item) => item.packed).length;
    final fraction = total == 0 ? 0.0 : packed / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Packed $packed of $total',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripListProvider);
    final packingAsync = _selectedTripId == null
        ? const AsyncValue<List<PackingItem>>.data([])
        : ref.watch(packingListProvider(_selectedTripId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Packing Lists')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tripsAsync.when(
              data: (trips) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select a trip'),
                  initialValue: _selectedTripId,
                  items: trips
                      .map(
                        (trip) => DropdownMenuItem<String>(
                          value: trip.id,
                          child: Text('${trip.tripName} (${trip.city})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTripId = value;
                      _packingSummary = null;
                      _packingTips = [];
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Unable to load trips: $error'),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Generate Packing List',
              icon: Icons.auto_awesome_rounded,
              onPressed: _selectedTripId == null ? null : _generatePacking,
            ),
            const SizedBox(height: 16),
            if (_packingSummary != null) ...[
              Text(
                _packingSummary!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: packingAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No packing items yet. Generate a list to get started.',
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPackingProgress(items),
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildPackingItem(items[index]),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Text('Unable to load packing list: $error'),
              ),
            ),
            if (_packingTips.isNotEmpty) ...[
              const Divider(),
              const Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._packingTips.map((tip) => Text('• $tip')),
            ],
          ],
        ),
      ),
    );
  }
}
