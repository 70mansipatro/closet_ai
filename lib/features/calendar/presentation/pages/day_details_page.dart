import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/calendar_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/gradient_button.dart';

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

          final statusColor = _statusColor(status.toString());

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    status.toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Notes: $notes'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Wear Today',
                        icon: Icons.checkroom_rounded,
                        variant: GradientButtonVariant.success,
                        onPressed: () async {
                          final wear = ref.read(wearTodayActionProvider);
                          final messenger = ScaffoldMessenger.maybeOf(
                            context,
                          );
                          try {
                            await wear(outfitId);
                            if (!mounted) return;
                            messenger?.showSnackBar(
                              const SnackBar(
                                content: Text('Marked as worn'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger?.showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
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

  /// Purely cosmetic mapping from a status label to an accent color.
  /// Does not affect status values or any business logic.
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'worn':
      case 'completed':
        return AppColors.green;
      case 'scheduled':
        return AppColors.purple;
      case 'skipped':
      case 'cancelled':
        return AppColors.error;
      case 'planned':
      default:
        return AppColors.blue;
    }
  }
}
