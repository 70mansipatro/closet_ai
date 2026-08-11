import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/admin_dashboard.dart';
import '../providers/admin_providers.dart';
import '../widgets/kpi_card.dart';

class _RangeOption {
  const _RangeOption(this.label, this.value);
  final String label;
  final String? value;
}

const _rangeOptions = [
  _RangeOption('Today', 'today'),
  _RangeOption('7 Days', '7d'),
  _RangeOption('30 Days', '30d'),
  _RangeOption('3 Months', '3m'),
  _RangeOption('6 Months', '6m'),
  _RangeOption('1 Year', '1y'),
  _RangeOption('All Time', null),
];

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final selectedRange = ref.watch(dashboardRangeProvider);
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _rangeOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: selectedRange == option.value,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(dashboardRangeProvider.notifier).state =
                          option.value;
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          dashboardAsync.when(
            data: (summary) => _buildKpis(summary, currency),
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
                    Text('Unable to load dashboard: $error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(adminDashboardProvider),
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

  Widget _buildKpis(AdminDashboardSummary summary, NumberFormat currency) {
    return KpiGrid(
      cards: [
        KpiCard(
          label: 'Total Users',
          value: summary.totalUsers.toString(),
          icon: Icons.people_outline,
          color: Colors.indigo,
        ),
        KpiCard(
          label: 'Active Users',
          value: summary.activeUsers.toString(),
          icon: Icons.person_outline,
          color: Colors.blue,
        ),
        KpiCard(
          label: 'Premium Users',
          value: summary.premiumUsers.toString(),
          icon: Icons.workspace_premium_outlined,
          color: Colors.amber,
        ),
        KpiCard(
          label: 'Free Users',
          value: summary.freeUsers.toString(),
          icon: Icons.person_outline,
          color: Colors.teal,
        ),
        KpiCard(
          label: 'Suspended Users',
          value: summary.suspendedUsers.toString(),
          icon: Icons.block_outlined,
          color: Colors.red,
        ),
        KpiCard(
          label: 'Active Subscriptions',
          value: summary.activeSubscriptions.toString(),
          icon: Icons.card_membership_outlined,
          color: Colors.green,
        ),
        KpiCard(
          label: 'Expired Subscriptions',
          value: summary.expiredSubscriptions.toString(),
          icon: Icons.event_busy_outlined,
          color: Colors.orange,
        ),
        KpiCard(
          label: 'Successful Payments',
          value: summary.successfulPayments.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        KpiCard(
          label: 'Failed Payments',
          value: summary.failedPayments.toString(),
          icon: Icons.error_outline,
          color: Colors.red,
        ),
        KpiCard(
          label: 'Revenue Today',
          value: currency.format(summary.revenueToday),
          icon: Icons.payments_outlined,
          color: Colors.purple,
        ),
        KpiCard(
          label: 'Revenue Month',
          value: currency.format(summary.revenueMonth),
          icon: Icons.payments_outlined,
          color: Colors.purple,
        ),
        KpiCard(
          label: 'Revenue Year',
          value: currency.format(summary.revenueYear),
          icon: Icons.payments_outlined,
          color: Colors.purple,
        ),
        KpiCard(
          label: 'Net Revenue',
          value: currency.format(summary.netRevenue),
          icon: Icons.trending_up_outlined,
          color: Colors.deepPurple,
        ),
        KpiCard(
          label: 'AI Requests',
          value: summary.aiRequests.toString(),
          icon: Icons.auto_awesome_outlined,
          color: Colors.pink,
        ),
        KpiCard(
          label: 'Wardrobe Items',
          value: summary.wardrobeItems.toString(),
          icon: Icons.checkroom_outlined,
          color: Colors.cyan,
        ),
        KpiCard(
          label: 'Outfits Created',
          value: summary.outfitsCreated.toString(),
          icon: Icons.style_outlined,
          color: Colors.lightBlue,
        ),
        KpiCard(
          label: 'Trips Created',
          value: summary.tripsCreated.toString(),
          icon: Icons.flight_outlined,
          color: Colors.brown,
        ),
        KpiCard(
          label: 'Laundry Records',
          value: summary.laundryRecords.toString(),
          icon: Icons.local_laundry_service_outlined,
          color: Colors.blueGrey,
        ),
      ],
    );
  }
}
