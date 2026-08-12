import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/kpi_card.dart';

const _rangeOptions = <String, String>{
  'today': 'Today',
  '7d': '7 Days',
  '30d': '30 Days',
  '3m': '3 Months',
  '6m': '6 Months',
  '1y': '1 Year',
};

String _money(num? value) {
  final amount = (value ?? 0).toDouble();
  return '₹${amount.toStringAsFixed(0)}';
}

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() =>
      _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(adminRevenueProvider);
    final range = ref.watch(revenueRangeProvider) ?? '30d';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminRevenueProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Revenue', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _rangeOptions.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: range == entry.key,
                  onSelected: (_) => ref
                      .read(revenueRangeProvider.notifier)
                      .state = entry.key,
                ),
            ],
          ),
          const SizedBox(height: 16),
          revenueAsync.when(
            data: (data) {
              final summary = Map<String, dynamic>.from(
                data['summary'] as Map? ?? {},
              );
              final trend = (data['trend'] as List? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KpiGrid(
                    cards: [
                      KpiCard(
                        label: 'Today',
                        value: _money(summary['today'] as num?),
                        icon: Icons.today_outlined,
                        color: AppColors.blue,
                      ),
                      KpiCard(
                        label: 'This Month',
                        value: _money(summary['month'] as num?),
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.brightBlue,
                      ),
                      KpiCard(
                        label: 'This Year',
                        value: _money(summary['year'] as num?),
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.purple,
                      ),
                      KpiCard(
                        label: 'Gross Revenue',
                        value: _money(summary['grossRevenue'] as num?),
                        icon: Icons.trending_up_outlined,
                        color: AppColors.success,
                      ),
                      KpiCard(
                        label: 'Refunds',
                        value: _money(summary['refunds'] as num?),
                        icon: Icons.undo_outlined,
                        color: AppColors.orange,
                      ),
                      KpiCard(
                        label: 'Net Revenue',
                        value: _money(summary['netRevenue'] as num?),
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.teal,
                      ),
                      KpiCard(
                        label: 'Successful Payments',
                        value: '${summary['successfulPayments'] ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      KpiCard(
                        label: 'Failed Payments',
                        value: '${summary['failedPayments'] ?? 0}',
                        icon: Icons.error_outline,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Revenue Trend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildTrendChart(trend),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load revenue: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminRevenueProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trend) {
    final points = trend
        .map((item) {
          final revenue = item['revenue'] is num
              ? (item['revenue'] as num).toDouble()
              : double.tryParse(item['revenue']?.toString() ?? '') ?? 0;
          final period = item['period']?.toString() ?? '';
          return {'period': period, 'revenue': revenue};
        })
        .toList();

    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No revenue data for this period.'),
      );
    }

    final maxValue = points
        .map((item) => item['revenue'] as double)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxValue * 1.1).clamp(1, double.infinity),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final period = points[index]['period'] as String;
                  final label = period.length > 5
                      ? period.substring(period.length - 5)
                      : period;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: AppColors.success,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i]['revenue'] as double),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
