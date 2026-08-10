import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/calendar_providers.dart';
import '../../../ai/data/outfit_repository.dart';

class MonthlyCalendarPage extends ConsumerWidget {
  const MonthlyCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider);
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Calendar')),
      body: Column(
        children: [
          SizedBox(
            height: 120,
            child: outfitsAsync.when(
              data: (data) {
                final items = data['data'] ?? [];
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (items as List).length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Draggable<String>(
                        data: item['_id']?.toString() ?? '',
                        feedback: Material(
                          child: Chip(
                            label: Text(
                              item['reason'] ?? item['top'] ?? 'Outfit',
                            ),
                          ),
                        ),
                        child: Chip(
                          label: Text(
                            item['reason'] ?? item['top'] ?? 'Outfit',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Failed to load outfits: $e')),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(today.year, today.month, day);
                return DragTarget<String>(
                  onAcceptWithDetails: (details) async {
                    final outfitId = details.data;
                    await ref
                        .read(calendarRepositoryProvider)
                        .schedule(
                          payload: {
                            'date': date.toIso8601String(),
                            'outfitId': outfitId,
                          },
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Outfit scheduled')),
                      );
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Card(child: Center(child: Text(day.toString())));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final outfitsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = OutfitRepository(ref.read(apiClientProvider));
  final resp = await repo.fetchOutfits();
  return resp;
});
