import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/calendar_providers.dart';

class DayDetailsPage extends ConsumerStatefulWidget {
  final DateTime date;
  const DayDetailsPage({super.key, required this.date});

  @override
  ConsumerState<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends ConsumerState<DayDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(calendarByDateProvider(widget.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Day Details - ${widget.date.toIso8601String().split('T').first}',
        ),
      ),
      body: asyncData.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text('No outfit scheduled for this day.'));
          }

          final outfitId = data['outfitId']?.toString();
          final notes = data['notes'] ?? '';
          final status = data['status'] ?? 'Planned';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Notes: $notes'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final wear = ref.read(wearTodayActionProvider);
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        try {
                          await wear(outfitId);
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            const SnackBar(content: Text('Marked as worn')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                      child: const Text('Wear Today'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // navigate to schedule/edit page
                        Navigator.of(context).pushNamed('/calendar/schedule');
                      },
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading day: $e')),
      ),
    );
  }
}
