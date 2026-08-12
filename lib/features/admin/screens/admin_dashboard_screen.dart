import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../widgets/gradient_card.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two headline tiles get the emphasized gradient treatment; the
        // remaining KPIs stay as plain, data-dense themed cards.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HighlightKpiTile(
                icon: Icons.people_outline,
                label: 'Total Users',
                value: summary.totalUsers.toString(),
                gradient: AppGradients.blueViolet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HighlightKpiTile(
                icon: Icons.trending_up_outlined,
                label: 'Net Revenue',
                value: currency.format(summary.netRevenue),
                gradient: AppGradients.premium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        KpiGrid(
          cards: [
            KpiCard(
              label: 'Active Users',
              value: summary.activeUsers.toString(),
              icon: Icons.person_outline,
              color: AppColors.blue,
            ),
            KpiCard(
              label: 'Premium Users',
              value: summary.premiumUsers.toString(),
              icon: Icons.workspace_premium_outlined,
              color: AppColors.gold,
            ),
            KpiCard(
              label: 'Free Users',
              value: summary.freeUsers.toString(),
              icon: Icons.person_outline,
              color: AppColors.teal,
            ),
            KpiCard(
              label: 'Suspended Users',
              value: summary.suspendedUsers.toString(),
              icon: Icons.block_outlined,
              color: AppColors.error,
            ),
            KpiCard(
              label: 'Active Subscriptions',
              value: summary.activeSubscriptions.toString(),
              icon: Icons.card_membership_outlined,
              color: AppColors.success,
            ),
            KpiCard(
              label: 'Expired Subscriptions',
              value: summary.expiredSubscriptions.toString(),
              icon: Icons.event_busy_outlined,
              color: AppColors.orange,
            ),
            KpiCard(
              label: 'Successful Payments',
              value: summary.successfulPayments.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            KpiCard(
              label: 'Failed Payments',
              value: summary.failedPayments.toString(),
              icon: Icons.error_outline,
              color: AppColors.error,
            ),
            KpiCard(
              label: 'Revenue Today',
              value: currency.format(summary.revenueToday),
              icon: Icons.payments_outlined,
              color: AppColors.purple,
            ),
            KpiCard(
              label: 'Revenue Month',
              value: currency.format(summary.revenueMonth),
              icon: Icons.payments_outlined,
              color: AppColors.pink,
            ),
            KpiCard(
              label: 'Revenue Year',
              value: currency.format(summary.revenueYear),
              icon: Icons.payments_outlined,
              color: AppColors.brightBlue,
            ),
            KpiCard(
              label: 'AI Requests',
              value: summary.aiRequests.toString(),
              icon: Icons.auto_awesome_outlined,
              color: AppColors.deepPurple,
            ),
            KpiCard(
              label: 'Wardrobe Items',
              value: summary.wardrobeItems.toString(),
              icon: Icons.checkroom_outlined,
              color: AppColors.cyan,
            ),
            KpiCard(
              label: 'Outfits Created',
              value: summary.outfitsCreated.toString(),
              icon: Icons.style_outlined,
              color: AppColors.brightBlue,
            ),
            KpiCard(
              label: 'Trips Created',
              value: summary.tripsCreated.toString(),
              icon: Icons.flight_outlined,
              color: AppColors.orange,
            ),
            KpiCard(
              label: 'Laundry Records',
              value: summary.laundryRecords.toString(),
              icon: Icons.local_laundry_service_outlined,
              color: AppColors.teal,
            ),
          ],
        ),
      ],
    );
  }
}

/// A gradient-emphasized headline KPI tile, used sparingly for the 1-2 most
/// important metrics on the dashboard. The remaining KPIs stay on the plain
/// themed [KpiCard] so the panel reads as a data-dense admin tool rather
/// than a marketing screen.
class _HighlightKpiTile extends StatelessWidget {
  const _HighlightKpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textOnDark),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
