import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Normalizes a raw analytics list entry (values may be num or String) into
/// a `{label, count}` pair using the given keys.
List<Map<String, dynamic>> _normalize(
  List<dynamic>? raw, {
  String labelKey = 'label',
  String valueKey = 'count',
}) {
  return (raw ?? const [])
      .map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final label = map[labelKey]?.toString() ?? '';
        final value = map[valueKey];
        final count = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '') ?? 0;
        return {'label': label, 'count': count};
      })
      .where((item) => item['label'] != '')
      .toList();
}

/// Shared bar chart used by every analytics tab for breakdown/growth series.
/// Pass `labelKey`/`valueKey` to match the field names of the source data
/// (e.g. `period`/`count` for growth series, `feature`/`count` for AI usage).
Widget buildAdminAnalyticsBarChart(
  List<dynamic>? raw, {
  String labelKey = 'label',
  String valueKey = 'count',
  Color color = Colors.blueAccent,
  int take = 8,
  String emptyMessage = 'No data available yet.',
}) {
  final items = _normalize(raw, labelKey: labelKey, valueKey: valueKey)
      .where((item) => (item['count'] as double) > 0)
      .toList();

  if (items.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(emptyMessage),
    );
  }

  final bars = items.take(take).toList();
  final maxValue = bars
      .map((item) => item['count'] as double)
      .fold<double>(0, (prev, value) => value > prev ? value : prev);

  return SizedBox(
    height: 220,
    child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxValue + 1).clamp(1, double.infinity),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
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
              reservedSize: 56,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= bars.length) {
                  return const SizedBox.shrink();
                }
                final label = bars[index]['label'] as String;
                final trimmed = label.length > 8
                    ? label.substring(label.length - 8)
                    : label;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    trimmed,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['count'] as double,
                width: 18,
                color: color,
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

/// A simple textual breakdown list (label + count), used when a full chart
/// would be too dense (e.g. long category names).
Widget buildAdminAnalyticsBreakdownList(
  List<dynamic>? raw, {
  String labelKey = 'label',
  String valueKey = 'count',
  int take = 10,
  String emptyMessage = 'No data available yet.',
}) {
  final items = _normalize(raw, labelKey: labelKey, valueKey: valueKey);
  if (items.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(emptyMessage),
    );
  }
  return Column(
    children: [
      for (final item in items.take(take))
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(item['label'] as String),
          trailing: Text(
            (item['count'] as double).toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
    ],
  );
}

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Users'),
    Tab(text: 'AI'),
    Tab(text: 'Wardrobe'),
    Tab(text: 'Outfits'),
    Tab(text: 'Laundry'),
    Tab(text: 'Trips'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analyticsRangeProvider) ?? '30d';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _rangeOptions.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: range == entry.key,
                  onSelected: (_) => ref
                      .read(analyticsRangeProvider.notifier)
                      .state = entry.key,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UsersAnalyticsTab(),
              _AiAnalyticsTab(),
              _WardrobeAnalyticsTab(),
              _OutfitsAnalyticsTab(),
              _LaundryAnalyticsTab(),
              _TripsAnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsAsyncBody extends ConsumerWidget {
  const _AnalyticsAsyncBody({required this.domain, required this.builder});

  final String domain;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAnalyticsProvider(domain));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminAnalyticsProvider(domain));
      },
      child: async.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [builder(context, data)],
        ),
        loading: () => ListView(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load analytics: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(adminAnalyticsProvider(domain)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersAnalyticsTab extends StatelessWidget {
  const _UsersAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'users',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'Total',
                value: '${data['total'] ?? 0}',
                icon: Icons.people_outline,
              ),
              KpiCard(
                label: 'Active',
                value: '${data['active'] ?? 0}',
                icon: Icons.person_outline,
                color: Colors.green,
              ),
              KpiCard(
                label: 'Premium',
                value: '${data['premium'] ?? 0}',
                icon: Icons.workspace_premium_outlined,
                color: Colors.amber,
              ),
              KpiCard(
                label: 'Free',
                value: '${data['free'] ?? 0}',
                icon: Icons.person_off_outlined,
                color: Colors.grey,
              ),
              KpiCard(
                label: 'Suspended',
                value: '${data['suspended'] ?? 0}',
                icon: Icons.block_outlined,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Growth', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['growth'] as List?,
            labelKey: 'period',
            color: Colors.indigo,
            emptyMessage: 'No user growth data for this period.',
          ),
        ],
      ),
    );
  }
}

class _AiAnalyticsTab extends StatelessWidget {
  const _AiAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'ai',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'Total Requests',
                value: '${data['totalRequests'] ?? 0}',
                icon: Icons.auto_awesome_outlined,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Requests by Feature',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['byFeature'] as List?,
            labelKey: 'feature',
            color: Colors.purple,
            emptyMessage: 'No AI feature usage recorded yet.',
          ),
          const SizedBox(height: 24),
          Text(
            'Requests by Period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          buildAdminAnalyticsBreakdownList(
            data['byPeriod'] as List?,
            labelKey: 'period',
            emptyMessage: 'No AI usage data for this period.',
          ),
        ],
      ),
    );
  }
}

class _WardrobeAnalyticsTab extends StatelessWidget {
  const _WardrobeAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'wardrobe',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'Total Items',
                value: '${data['totalItems'] ?? 0}',
                icon: Icons.checkroom_outlined,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'By Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          buildAdminAnalyticsBreakdownList(
            data['byCategory'] as List?,
            emptyMessage: 'No category data yet.',
          ),
          const SizedBox(height: 16),
          Text('By Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBreakdownList(
            data['byColor'] as List?,
            emptyMessage: 'No color data yet.',
          ),
          const SizedBox(height: 16),
          Text('By Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBreakdownList(
            data['byType'] as List?,
            emptyMessage: 'No type data yet.',
          ),
          const SizedBox(height: 24),
          Text('Growth', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['growth'] as List?,
            labelKey: 'period',
            color: Colors.blue,
            emptyMessage: 'No wardrobe growth data for this period.',
          ),
        ],
      ),
    );
  }
}

class _OutfitsAnalyticsTab extends StatelessWidget {
  const _OutfitsAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'outfits',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'Total',
                value: '${data['totalOutfits'] ?? 0}',
                icon: Icons.style_outlined,
              ),
              KpiCard(
                label: 'Favorites',
                value: '${data['favoriteOutfits'] ?? 0}',
                icon: Icons.favorite_outline,
                color: Colors.pink,
              ),
              KpiCard(
                label: 'Planned',
                value: '${data['planned'] ?? 0}',
                icon: Icons.event_note_outlined,
                color: Colors.blue,
              ),
              KpiCard(
                label: 'Worn',
                value: '${data['worn'] ?? 0}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              KpiCard(
                label: 'Skipped',
                value: '${data['skipped'] ?? 0}',
                icon: Icons.cancel_outlined,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'By Occasion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['byOccasion'] as List?,
            color: Colors.deepOrange,
            emptyMessage: 'No occasion data yet.',
          ),
          const SizedBox(height: 24),
          Text('Growth', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['growth'] as List?,
            labelKey: 'period',
            color: Colors.teal,
            emptyMessage: 'No outfit growth data for this period.',
          ),
        ],
      ),
    );
  }
}

class _LaundryAnalyticsTab extends StatelessWidget {
  const _LaundryAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'laundry',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'History Records',
                value: '${data['totalHistoryRecords'] ?? 0}',
                icon: Icons.local_laundry_service_outlined,
                color: Colors.cyan,
              ),
              KpiCard(
                label: 'Overdue',
                value: '${data['overdue'] ?? 0}',
                icon: Icons.warning_amber_outlined,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('By Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          buildAdminAnalyticsBarChart(
            data['byStatus'] as List?,
            color: Colors.cyan,
            emptyMessage: 'No laundry status data yet.',
          ),
        ],
      ),
    );
  }
}

class _TripsAnalyticsTab extends StatelessWidget {
  const _TripsAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return _AnalyticsAsyncBody(
      domain: 'trips',
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            cards: [
              KpiCard(
                label: 'Total',
                value: '${data['total'] ?? 0}',
                icon: Icons.flight_outlined,
              ),
              KpiCard(
                label: 'Upcoming',
                value: '${data['upcoming'] ?? 0}',
                icon: Icons.upcoming_outlined,
                color: Colors.blue,
              ),
              KpiCard(
                label: 'Completed',
                value: '${data['completed'] ?? 0}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              KpiCard(
                label: 'Packing Lists',
                value: '${data['packingLists'] ?? 0}',
                icon: Icons.list_alt_outlined,
                color: Colors.indigo,
              ),
              KpiCard(
                label: 'Packed Items',
                value: '${data['packedItems'] ?? 0}',
                icon: Icons.luggage_outlined,
                color: Colors.teal,
              ),
              KpiCard(
                label: 'Unpacked Items',
                value: '${data['unpackedItems'] ?? 0}',
                icon: Icons.inventory_2_outlined,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'By Destination',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          buildAdminAnalyticsBreakdownList(
            data['byDestination'] as List?,
            take: 10,
            emptyMessage: 'No destination data yet.',
          ),
        ],
      ),
    );
  }
}
