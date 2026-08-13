import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../widgets/gradient_card.dart';
import 'analytics_anim.dart';

/// The dashboard's headline card: 4 top-line wardrobe metrics pulled straight
/// from the overview / wear / cost analytics responses. No trend arrows are
/// shown because the backend does not provide period-over-period deltas —
/// inventing them would misrepresent the data.
class AnalyticsHeroCard extends StatelessWidget {
  const AnalyticsHeroCard({
    super.key,
    required this.overview,
    required this.wear,
    required this.cost,
  });

  final Map<String, dynamic> overview;
  final Map<String, dynamic> wear;
  final Map<String, dynamic> cost;

  @override
  Widget build(BuildContext context) {
    final totalItems = (overview['wardrobeCount'] as num?) ?? 0;
    final totalWears = (overview['totalWears'] as num?) ?? 0;
    final wardrobeValue = (cost['totalWardrobeValue'] as num?) ?? 0;

    final mostWornItems = wear['mostWornItems'] as List<dynamic>? ?? const [];
    final mostWorn = mostWornItems.isNotEmpty
        ? (mostWornItems.first as Map)['name']?.toString() ?? '—'
        : '—';

    return GradientCard(
      gradient: AppGradients.blueViolet,
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined,
                  color: AppColors.textOnDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Wardrobe at a Glance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 18,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _HeroStat(
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Items',
                      value: CountUpNumber(
                        value: totalItems,
                        style: _valueStyle(context),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroStat(
                      icon: Icons.checkroom_outlined,
                      label: 'Total Wears',
                      value: CountUpNumber(
                        value: totalWears,
                        style: _valueStyle(context),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroStat(
                      icon: Icons.star_outline,
                      label: 'Most Worn',
                      value: Text(
                        mostWorn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _valueStyle(context).copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _HeroStat(
                      icon: Icons.payments_outlined,
                      label: 'Wardrobe Value',
                      value: CountUpNumber(
                        value: wardrobeValue,
                        prefix: '₹',
                        style: _valueStyle(context),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(BuildContext context) =>
      (Theme.of(context).textTheme.headlineSmall ?? const TextStyle(fontSize: 24)).copyWith(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w800,
      );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textOnDarkMuted, size: 18),
        const SizedBox(height: 6),
        value,
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// Formats a rupee amount with thousands separators, e.g. ₹42,500.
String formatRupees(num value) => '₹${NumberFormat('#,##0').format(value)}';
