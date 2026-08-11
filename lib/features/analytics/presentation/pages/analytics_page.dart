import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analytics_providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _dateFilter = 'this_month';

  @override
  void initState() {
    super.initState();
    _applyFilter('this_month');
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to = now;

    switch (filter) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'this_week':
        final weekday = now.weekday;
        from = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        break;
      case 'this_month':
        from = DateTime(now.year, now.month, 1);
        break;
      case '30_days':
        from = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
      case '3_months':
        from = DateTime(now.year, now.month - 2, 1);
        break;
      case '6_months':
        from = DateTime(now.year, now.month - 5, 1);
        break;
      case 'this_year':
        from = DateTime(now.year, 1, 1);
        break;
      default:
        from = DateTime(now.year, now.month, 1);
    }

    ref.read(analyticsFilterProvider.notifier).state = {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'interval': _dateFilter == 'this_month' ? 'monthly' : 'weekly',
    };
    setState(() {
      _dateFilter = filter;
    });
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _dateFilter == value,
      onSelected: (selected) {
        if (selected) _applyFilter(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final wearAsync = ref.watch(wearAnalyticsProvider);
    final outfitAsync = ref.watch(outfitAnalyticsProvider);
    final categoryAsync = ref.watch(categoryAnalyticsProvider);
    final colorAsync = ref.watch(colorAnalyticsProvider);
    final laundryAsync = ref.watch(laundryAnalyticsProvider);
    final costAsync = ref.watch(costAnalyticsProvider);
    final insightAsync = ref.watch(analyticsInsightsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Style Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsOverviewProvider);
          ref.invalidate(wearAnalyticsProvider);
          ref.invalidate(outfitAnalyticsProvider);
          ref.invalidate(categoryAnalyticsProvider);
          ref.invalidate(colorAnalyticsProvider);
          ref.invalidate(laundryAnalyticsProvider);
          ref.invalidate(costAnalyticsProvider);
          ref.invalidate(analyticsInsightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Understand your wardrobe and wearing habits',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('Today', 'today'),
                _buildFilterChip('This Week', 'this_week'),
                _buildFilterChip('This Month', 'this_month'),
                _buildFilterChip('30 Days', '30_days'),
                _buildFilterChip('3 Months', '3_months'),
                _buildFilterChip('6 Months', '6_months'),
                _buildFilterChip('This Year', 'this_year'),
              ],
            ),
            const SizedBox(height: 16),
            overviewAsync.when(
              data: (overview) => Row(
                children: [
                  _buildSummaryCard(
                    'Total Items',
                    overview['wardrobeCount']?.toString() ?? '0',
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    'Total Wears',
                    overview['totalWears']?.toString() ?? '0',
                    Icons.checkroom,
                    Colors.green,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Unable to load overview: $error')),
            ),
            const SizedBox(height: 16),
            wearAsync.when(
              data: (wear) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wear Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildAnalyticsTile(
                    'Unique Items Worn',
                    wear['uniqueItemsWorn']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Average Wears Per Item',
                    wear['averageWearsPerItem']?.toString() ?? '0',
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Unable to load wear analytics: $error')),
            ),
            const SizedBox(height: 16),
            outfitAsync.when(
              data: (outfit) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outfit Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildAnalyticsTile(
                    'Planned Outfits',
                    outfit['plannedOutfits']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Worn Outfits',
                    outfit['wornOutfits']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Skipped Outfits',
                    outfit['skippedOutfits']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Completion Rate',
                    '${outfit['completionRate']?.toString() ?? '0'}%',
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Unable to load outfit analytics: $error'),
              ),
            ),
            const SizedBox(height: 16),
            categoryAsync.when(
              data: (categories) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryBarChart(categories),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Unable to load category analytics: $error'),
              ),
            ),
            const SizedBox(height: 16),
            colorAsync.when(
              data: (colors) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Usage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...colors
                      .take(5)
                      .map(
                        (item) => _buildAnalyticsTile(
                          item['label']?.toString() ?? 'Unknown',
                          item['count']?.toString() ?? '0',
                        ),
                      ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Unable to load color analytics: $error')),
            ),
            const SizedBox(height: 16),
            laundryAsync.when(
              data: (laundry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laundry Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildAnalyticsTile(
                    'Dirty',
                    laundry['currentlyDirty']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Washing',
                    laundry['currentlyWashing']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Drying',
                    laundry['currentlyDrying']?.toString() ?? '0',
                  ),
                  _buildAnalyticsTile(
                    'Ready',
                    laundry['readyItems']?.toString() ?? '0',
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Unable to load laundry analytics: $error'),
              ),
            ),
            const SizedBox(height: 16),
            costAsync.when(
              data: (cost) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cost Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildAnalyticsTile(
                    'Wardrobe Value',
                    '₹${cost['totalWardrobeValue']?.toString() ?? '0'}',
                  ),
                  _buildAnalyticsTile(
                    'Avg Cost / Wear',
                    '₹${cost['averageCostPerWear']?.toString() ?? '0'}',
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Unable to load cost analytics: $error')),
            ),
            const SizedBox(height: 16),
            insightAsync.when(
              data: (insight) => _buildInsights(insight),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Unable to load insights: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTile(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryBarChart(List<dynamic> categories) {
    final filtered = categories
        .map((item) {
          final label = item['label']?.toString() ?? '';
          final count = item['count'] is num
              ? (item['count'] as num).toInt()
              : int.tryParse(item['count']?.toString() ?? '') ?? 0;
          return {'label': label, 'count': count};
        })
        .where((item) => (item['count'] as int) > 0)
        .toList();

    if (filtered.isEmpty) {
      return const Text('No category data available yet.');
    }

    final bars = filtered.take(5).toList();
    final maxValue = bars
        .map((item) => item['count'] as int)
        .fold<int>(0, (prev, value) => value > prev ? value : prev)
        .toDouble();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxValue + 1).clamp(1, double.infinity),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  final label = bars[index]['label'] as String;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                reservedSize: 64,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['count'] as int).toDouble(),
                  width: 18,
                  color: Colors.blueAccent,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInsights(Map<String, dynamic> insight) {
    final summary = insight['summary']?.toString() ?? '';
    final recommendations = insight['recommendations'] as List<dynamic>? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(summary),
            const SizedBox(height: 12),
            if (recommendations.isNotEmpty) ...[
              const Text(
                'Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recommendations.map(
                (item) =>
                    Text('• ${item['type']}: ${item['clothingId'] ?? ''}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
