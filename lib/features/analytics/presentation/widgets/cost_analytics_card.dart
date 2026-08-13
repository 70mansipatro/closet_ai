import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'analytics_anim.dart';
import 'analytics_hero_card.dart' show formatRupees;

/// "Wardrobe Value" section. Both figures come straight from
/// `costAnalyticsProvider` — no invented financial calculations or
/// thresholds, just the two real numbers presented clearly.
class CostAnalyticsCard extends StatelessWidget {
  const CostAnalyticsCard({super.key, required this.cost});

  final Map<String, dynamic> cost;

  @override
  Widget build(BuildContext context) {
    final totalValue = (cost['totalWardrobeValue'] as num?) ?? 0;
    final avgCostPerWear = (cost['averageCostPerWear'] as num?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wardrobe Value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Understand the value of your clothing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 18),
            CountUpNumber(
              value: totalValue,
              prefix: '₹',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatRupees(avgCostPerWear)} / wear',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.insights_outlined, size: 18, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Efficiency',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Across your tracked wears, each item costs ${formatRupees(avgCostPerWear)} on average per wear.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
