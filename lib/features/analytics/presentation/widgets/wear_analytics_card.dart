import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Wear Performance" section: unique items worn, average wears per item,
/// and total wears — plus a real historical trend line when the backend
/// provides one (wearCountByMonth/Week/Day). No chart data is fabricated;
/// if none of those series has entries, the KPI trio stands on its own.
class WearAnalyticsCard extends StatelessWidget {
  const WearAnalyticsCard({super.key, required this.wear});

  final Map<String, dynamic> wear;

  List<dynamic> get _trend {
    for (final key in ['wearCountByMonth', 'wearCountByWeek', 'wearCountByDay']) {
      final series = wear[key] as List<dynamic>? ?? const [];
      if (series.isNotEmpty) return series;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final uniqueItemsWorn = (wear['uniqueItemsWorn'] as num?) ?? 0;
    final averageWearsPerItem = (wear['averageWearsPerItem'] as num?) ?? 0;
    final totalWears = (wear['totalWears'] as num?) ?? 0;
    final trend = _trend;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wear Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'How actively are you using your wardrobe?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _WearStat(icon: Icons.checkroom_outlined, value: '$uniqueItemsWorn', label: 'Unique Items'),
                _WearStat(icon: Icons.repeat, value: averageWearsPerItem.toStringAsFixed(1), label: 'Avg / Item'),
                _WearStat(icon: Icons.bar_chart_outlined, value: '$totalWears', label: 'Total Wears'),
              ],
            ),
            if (trend.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 110,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < trend.length; i++)
                            FlSpot(i.toDouble(), _countOf(trend[i])),
                        ],
                        isCurved: true,
                        color: AppColors.brightBlue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.brightBlue.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _countOf(dynamic entry) {
    final count = (entry as Map)['count'];
    return count is num ? count.toDouble() : double.tryParse(count?.toString() ?? '') ?? 0;
  }
}

class _WearStat extends StatelessWidget {
  const _WearStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
