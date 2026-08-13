import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'analytics_states.dart';

const List<Color> _chartPalette = [
  AppColors.cyan,
  AppColors.brightBlue,
  AppColors.purple,
  AppColors.pink,
  AppColors.green,
  AppColors.orange,
];

/// "Wardrobe Composition" section. The backend's `/analytics/categories`
/// endpoint returns `{category, wearCount}` entries (NOT `{label, count}` —
/// the previous implementation read the wrong keys here, which silently
/// rendered "Unknown"/0 for every bar).
class CategoryAnalyticsCard extends StatelessWidget {
  const CategoryAnalyticsCard({super.key, required this.categories});

  final List<dynamic> categories;

  List<Map<String, dynamic>> get _bars {
    return categories
        .map((raw) {
          final item = raw as Map;
          final label = item['category']?.toString() ?? 'Unknown';
          final count = item['wearCount'];
          final value = count is num
              ? count.toDouble()
              : double.tryParse(count?.toString() ?? '') ?? 0;
          return {'label': label, 'count': value};
        })
        .where((item) => (item['count'] as double) > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wardrobe Composition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'What fills your wardrobe?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            if (bars.isEmpty)
              const AnalyticsEmptyState(
                icon: Icons.category_outlined,
                title: 'No Data Yet',
                message: 'Start wearing and tracking your outfits to unlock wardrobe insights.',
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 240,
                  width: (bars.length * 64).clamp(240, double.infinity).toDouble(),
                  child: _CategoryBarChart(bars: bars),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Top Category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bars.first['label'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.bars});

  final List<Map<String, dynamic>> bars;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars
        .map((item) => item['count'] as double)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxValue + 1).clamp(1, double.infinity),
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              rod.toY.toInt().toString(),
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= bars.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    bars[index]['label'] as String,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: 64,
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: bars.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            showingTooltipIndicators: [0],
            barRods: [
              BarChartRodData(
                toY: item['count'] as double,
                width: 22,
                color: _chartPalette[index % _chartPalette.length],
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
