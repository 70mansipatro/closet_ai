import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'analytics_states.dart';

/// "Your Color Story" section. The backend's `/analytics/colors` endpoint
/// returns `{color, count, percentage}` entries (NOT `{label, count}` — the
/// previous implementation read the wrong keys here). `percentage` is
/// already computed server-side from real wardrobe counts, so it's reused
/// as-is rather than recomputed in Flutter.
class ColorAnalyticsCard extends StatelessWidget {
  const ColorAnalyticsCard({super.key, required this.colors});

  final List<dynamic> colors;

  List<Map<String, dynamic>> get _rows {
    final rows = colors.map((raw) {
      final item = raw as Map;
      final count = item['count'];
      final percentage = item['percentage'];
      return {
        'label': item['color']?.toString() ?? 'Unknown',
        'count': count is num ? count.toInt() : int.tryParse(count?.toString() ?? '') ?? 0,
        'percentage': percentage is num ? percentage.toDouble() : double.tryParse(percentage?.toString() ?? '') ?? 0.0,
      };
    }).where((item) => (item['count'] as int) > 0).toList();
    rows.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Color Story',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'The colors you wear most',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const AnalyticsEmptyState(
                icon: Icons.palette_outlined,
                title: 'No Data Yet',
                message: 'Start wearing and tracking your outfits to unlock wardrobe insights.',
              )
            else
              Column(
                children: [
                  for (var i = 0; i < rows.length.clamp(0, 8); i++) ...[
                    _ColorRow(
                      label: rows[i]['label'] as String,
                      count: rows[i]['count'] as int,
                      percentage: rows[i]['percentage'] as double,
                      maxCount: rows.first['count'] as int,
                    ),
                    if (i != rows.length.clamp(0, 8) - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.count,
    required this.percentage,
    required this.maxCount,
  });

  final String label;
  final int count;
  final double percentage;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    final swatch = colorSwatchFromName(label);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: swatch,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value.clamp(0.03, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ),
      ],
    );
  }
}

/// Best-effort mapping from a wardrobe color name to a real swatch color, so
/// the ranking rows show a recognizable dot instead of a generic palette
/// color. Falls back to a neutral grey for unknown names — this is display
/// polish only, it never changes the underlying count/percentage data.
Color colorSwatchFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'black':
      return const Color(0xFF1A1A1A);
    case 'white':
      return const Color(0xFFF5F5F5);
    case 'grey':
    case 'gray':
      return const Color(0xFF9E9E9E);
    case 'blue':
      return AppColors.brightBlue;
    case 'navy':
    case 'navy blue':
      return const Color(0xFF1E2A5E);
    case 'red':
      return const Color(0xFFE53935);
    case 'maroon':
      return const Color(0xFF7B1E2B);
    case 'green':
      return AppColors.green;
    case 'olive':
      return const Color(0xFF6B8E23);
    case 'yellow':
      return const Color(0xFFFCD34D);
    case 'gold':
      return AppColors.gold;
    case 'orange':
      return AppColors.orange;
    case 'brown':
    case 'tan':
      return const Color(0xFF8D6E63);
    case 'beige':
    case 'cream':
    case 'ivory':
      return const Color(0xFFE8DCC8);
    case 'pink':
      return AppColors.pink;
    case 'purple':
      return AppColors.purple;
    case 'teal':
      return AppColors.teal;
    case 'cyan':
      return AppColors.cyan;
    case 'silver':
      return const Color(0xFFC0C0C0);
    case 'multicolor':
    case 'multi':
    case 'printed':
      return AppColors.deepPurple;
    default:
      return const Color(0xFFB0B0B0);
  }
}
