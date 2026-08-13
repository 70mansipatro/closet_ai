import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Outfit Performance" section: a donut chart breaking Planned / Worn /
/// Skipped outfits down, with the real completion rate highlighted in the
/// center and again as a call-out chip below the legend.
class OutfitAnalyticsCard extends StatelessWidget {
  const OutfitAnalyticsCard({super.key, required this.outfit});

  final Map<String, dynamic> outfit;

  @override
  Widget build(BuildContext context) {
    final planned = ((outfit['plannedOutfits'] as num?) ?? 0).toDouble();
    final worn = ((outfit['wornOutfits'] as num?) ?? 0).toDouble();
    final skipped = ((outfit['skippedOutfits'] as num?) ?? 0).toDouble();
    final completionRate = (outfit['completionRate'] as num?) ?? 0;
    final total = planned + worn + skipped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outfit Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Plan or log an outfit to see your performance breakdown.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        sections: [
                          PieChartSectionData(
                            value: worn,
                            color: AppColors.green,
                            showTitle: false,
                            radius: 26,
                          ),
                          PieChartSectionData(
                            value: planned,
                            color: AppColors.brightBlue,
                            showTitle: false,
                            radius: 26,
                          ),
                          PieChartSectionData(
                            value: skipped,
                            color: AppColors.orange,
                            showTitle: false,
                            radius: 26,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${completionRate.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Outfit Success',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _LegendRow(color: AppColors.green, label: 'Worn Outfits', value: worn.toInt()),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.brightBlue, label: 'Planned Outfits', value: planned.toInt()),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.orange, label: 'Skipped Outfits', value: skipped.toInt()),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Completion Rate: ${completionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
