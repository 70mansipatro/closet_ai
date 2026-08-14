import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Extracts a representative thumbnail URL from a saved/generated outfit map
/// (the first recommended item's image), or null if none is available.
String? outfitThumbnailUrl(Map<String, dynamic> outfit) {
  final items = outfit['recommendedItems'];
  if (items is List) {
    for (final item in items) {
      if (item is Map && item['imageUrl'] is String && (item['imageUrl'] as String).isNotEmpty) {
        return item['imageUrl'] as String;
      }
    }
  }
  return null;
}

/// A small placeholder tile shown in place of a missing/failed outfit thumbnail.
Widget fallbackOutfitThumbnail({double size = 44}) {
  return Container(
    width: size,
    height: size,
    color: AppColors.lightSurfaceAlt,
    child: const Icon(Icons.checkroom),
  );
}

/// "Worn ✓" / "Saved" pill shown on outfit list tiles.
class OutfitStatusBadge extends StatelessWidget {
  const OutfitStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWorn = status.toLowerCase() == 'worn';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isWorn ? AppColors.success.withValues(alpha: 0.15) : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isWorn ? 'Worn ✓' : 'Saved',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isWorn ? AppColors.success : theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
