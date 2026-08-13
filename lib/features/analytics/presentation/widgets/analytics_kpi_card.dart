import 'package:flutter/material.dart';

import 'analytics_anim.dart';

/// Quick-glance KPI tile: icon, animated large value, label, and a small
/// contextual subtitle. Meant to sit inside the existing responsive
/// `KpiGrid` (lib/features/admin/widgets/kpi_card.dart) alongside/instead of
/// plain `KpiCard`s, matching its visual language (bordered themed Card,
/// tinted icon chip) but with an extra subtitle line.
class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.subtitle,
    this.color,
    this.suffix = '',
    this.decimals = 0,
  });

  final String label;
  final num value;
  final IconData icon;
  final String subtitle;
  final Color? color;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(height: 6),
            CountUpNumber(
              value: value,
              suffix: suffix,
              decimals: decimals,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 10.5,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
