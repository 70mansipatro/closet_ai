import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Wardrobe Care" section: a compact, scan-friendly snapshot of current
/// laundry status counts.
class LaundryAnalyticsCard extends StatelessWidget {
  const LaundryAnalyticsCard({super.key, required this.laundry});

  final Map<String, dynamic> laundry;

  @override
  Widget build(BuildContext context) {
    final dirty = (laundry['currentlyDirty'] as num?) ?? 0;
    final washing = (laundry['currentlyWashing'] as num?) ?? 0;
    final drying = (laundry['currentlyDrying'] as num?) ?? 0;
    final ready = (laundry['readyItems'] as num?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wardrobe Care',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Current clothing care status',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _LaundryStatusTile(
                        icon: Icons.delete_outline,
                        label: 'Dirty',
                        subtitle: 'Currently dirty',
                        value: dirty,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _LaundryStatusTile(
                        icon: Icons.local_laundry_service_outlined,
                        label: 'Washing',
                        subtitle: 'Currently washing',
                        value: washing,
                        color: AppColors.brightBlue,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _LaundryStatusTile(
                        icon: Icons.dry_cleaning_outlined,
                        label: 'Drying',
                        subtitle: 'Currently drying',
                        value: drying,
                        color: AppColors.orange,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _LaundryStatusTile(
                        icon: Icons.check_circle_outline,
                        label: 'Ready',
                        subtitle: 'Ready to wear',
                        value: ready,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LaundryStatusTile extends StatelessWidget {
  const _LaundryStatusTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
