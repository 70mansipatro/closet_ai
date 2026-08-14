import 'package:cached_network_image/cached_network_image.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/ai_stylist/domain/chat_models.dart';
import 'package:closet_ai/features/calendar/application/calendar_providers.dart';
import 'package:closet_ai/features/dashboard/application/dashboard_providers.dart';
import 'package:closet_ai/features/wardrobe/application/wardrobe_state.dart';
import 'package:closet_ai/features/wardrobe/domain/wardrobe_item.dart';
import 'package:closet_ai/widgets/gradient_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ClothingRole { top, bottom, dress, outerwear, footwear, accessory }

_ClothingRole _roleForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'top':
    case 'activewear':
    case 'innerwear':
      return _ClothingRole.top;
    case 'bottom':
      return _ClothingRole.bottom;
    case 'dress':
      return _ClothingRole.dress;
    case 'outerwear':
      return _ClothingRole.outerwear;
    case 'shoes':
      return _ClothingRole.footwear;
    default:
      return _ClothingRole.accessory;
  }
}

String _clamp(String value, int max) =>
    value.length <= max ? value : value.substring(0, max);

/// The outfit/calendar validators reject temperature outside [-30, 60], so an
/// out-of-range or non-finite AI value is dropped rather than sent as-is.
num? _safeTemperature(num? value) {
  if (value == null) return null;
  final asDouble = value.toDouble();
  if (asDouble.isNaN || asDouble.isInfinite || asDouble < -30 || asDouble > 60) {
    return null;
  }
  return value;
}

/// Renders one [StylistRecommendation] as a card with real wardrobe images
/// and the Save/Wear/Favorite/Schedule/Try Another actions. Every clothing
/// item shown is resolved from the already-loaded wardrobe list — an id with
/// no match in the wardrobe is simply omitted, never invented.
class StylistRecommendationCard extends ConsumerStatefulWidget {
  const StylistRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTryAnother,
  });

  final StylistRecommendation recommendation;
  final VoidCallback? onTryAnother;

  @override
  ConsumerState<StylistRecommendationCard> createState() =>
      _StylistRecommendationCardState();
}

class _StylistRecommendationCardState
    extends ConsumerState<StylistRecommendationCard> {
  String? _outfitId;
  bool _favorite = false;
  bool _isSaving = false;
  bool _isWearing = false;
  bool _isFavoriting = false;
  bool _isScheduling = false;
  String? _actionError;
  String? _actionSuccess;

  List<WardrobeItem> _resolveItems(List<WardrobeItem> wardrobe) {
    final byId = {for (final item in wardrobe) item.id: item};
    return widget.recommendation.clothingIds
        .map((id) => byId[id])
        .whereType<WardrobeItem>()
        .toList();
  }

  Map<_ClothingRole, List<WardrobeItem>> _bucketByRole(
    List<WardrobeItem> items,
  ) {
    final buckets = <_ClothingRole, List<WardrobeItem>>{};
    for (final item in items) {
      buckets.putIfAbsent(_roleForCategory(item.category), () => []).add(item);
    }
    return buckets;
  }

  Map<String, dynamic> _buildSavePayload(List<WardrobeItem> items) {
    final rec = widget.recommendation;
    final buckets = _bucketByRole(items);
    String namesFor(_ClothingRole role) =>
        (buckets[role] ?? const []).map((item) => item.displayName).join(', ');
    final topNames = namesFor(_ClothingRole.top).isEmpty
        ? namesFor(_ClothingRole.dress)
        : namesFor(_ClothingRole.top);

    return {
      'occasion': _clamp(rec.occasion.isEmpty ? 'casual' : rec.occasion, 80),
      'weather': _clamp(rec.weather.isEmpty ? 'sunny' : rec.weather, 40),
      'style': _clamp(rec.style, 50),
      'reason': _clamp(rec.reason, 500),
      'outfitName': _clamp(rec.title, 120),
      'confidenceScore': (rec.rating * 10).clamp(0, 100),
      'aiGenerated': true,
      'top': _clamp(topNames, 120),
      'bottom': _clamp(namesFor(_ClothingRole.bottom), 120),
      'footwear': _clamp(namesFor(_ClothingRole.footwear), 120),
      'outerwear': _clamp(namesFor(_ClothingRole.outerwear), 120),
      'accessories': _clamp(namesFor(_ClothingRole.accessory), 120),
      'recommendedItems': items
          .map(
            (item) => {
              '_id': item.id,
              'name': item.displayName,
              'category': item.category,
            },
          )
          .toList(),
      if (_safeTemperature(rec.temperature) != null)
        'temperature': _safeTemperature(rec.temperature),
    };
  }

  Map<String, dynamic> _buildSchedulePayload(
    List<WardrobeItem> items,
    DateTime date,
  ) {
    final rec = widget.recommendation;
    final buckets = _bucketByRole(items);
    WardrobeItem? firstOf(_ClothingRole role) =>
        (buckets[role] ?? const []).isEmpty ? null : buckets[role]!.first;
    final top = firstOf(_ClothingRole.top) ?? firstOf(_ClothingRole.dress);
    final bottom = firstOf(_ClothingRole.bottom);
    final footwear = firstOf(_ClothingRole.footwear);
    final outerwear = firstOf(_ClothingRole.outerwear);
    final accessories = (buckets[_ClothingRole.accessory] ?? const [])
        .map((item) => item.id)
        .toList();
    final temperature = _safeTemperature(rec.temperature);

    return {
      'date': date.toIso8601String(),
      if (top != null) 'topId': top.id,
      if (bottom != null) 'bottomId': bottom.id,
      if (footwear != null) 'footwearId': footwear.id,
      if (outerwear != null) 'outerwearId': outerwear.id,
      if (accessories.isNotEmpty) 'accessories': accessories,
      'occasion': _clamp(rec.occasion.isEmpty ? 'casual' : rec.occasion, 80),
      'weather': _clamp(rec.weather.isEmpty ? 'sunny' : rec.weather, 40),
      if (temperature != null) 'temperature': temperature,
    };
  }

  Future<String?> _ensureSaved(List<WardrobeItem> items) async {
    if (_outfitId != null) return _outfitId;
    setState(() {
      _isSaving = true;
      _actionError = null;
    });
    try {
      final response = await ref
          .read(outfitRepositoryProvider)
          .saveOutfit(_buildSavePayload(items));
      final data = response['data'];
      final id = (data is Map ? data['_id'] : null)?.toString();
      if (id != null) {
        setState(() {
          _outfitId = id;
          _actionSuccess = 'Outfit saved.';
        });
      }
      return id;
    } on DioException catch (error) {
      setState(() => _actionError = ApiClient.extractErrorMessage(error));
      return null;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleWear(List<WardrobeItem> items) async {
    final outfitId = await _ensureSaved(items);
    if (outfitId == null) return;
    setState(() {
      _isWearing = true;
      _actionError = null;
    });
    try {
      await ref.read(outfitRepositoryProvider).wearOutfit(outfitId);
      setState(() => _actionSuccess = 'Marked as worn today.');
    } on DioException catch (error) {
      setState(() => _actionError = ApiClient.extractErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isWearing = false);
    }
  }

  Future<void> _handleFavorite(List<WardrobeItem> items) async {
    final outfitId = await _ensureSaved(items);
    if (outfitId == null) return;
    setState(() {
      _isFavoriting = true;
      _actionError = null;
    });
    try {
      final next = !_favorite;
      await ref
          .read(outfitRepositoryProvider)
          .toggleFavorite(outfitId, favorite: next);
      setState(() {
        _favorite = next;
        _actionSuccess = next ? 'Added to favorites.' : 'Removed from favorites.';
      });
    } on DioException catch (error) {
      setState(() => _actionError = ApiClient.extractErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isFavoriting = false);
    }
  }

  Future<void> _handleSchedule(List<WardrobeItem> items) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _isScheduling = true;
      _actionError = null;
    });
    try {
      await ref
          .read(calendarRepositoryProvider)
          .schedule(payload: _buildSchedulePayload(items, date));
      setState(
        () => _actionSuccess =
            'Scheduled for ${date.day}/${date.month}/${date.year}.',
      );
    } on DioException catch (error) {
      setState(() => _actionError = ApiClient.extractErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wardrobe = ref.watch(wardrobeControllerProvider).items;
    final items = _resolveItems(wardrobe);
    final rec = widget.recommendation;

    return GlassCard(
      accentColor: AppColors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  rec.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (rec.rating > 0) _RatingBadge(rating: rec.rating),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (rec.occasion.isNotEmpty)
                _MetaChip(icon: Icons.event_outlined, label: rec.occasion),
              if (rec.style.isNotEmpty)
                _MetaChip(icon: Icons.style_outlined, label: rec.style),
              if (rec.weather.isNotEmpty)
                _MetaChip(icon: Icons.wb_sunny_outlined, label: rec.weather),
              if (rec.temperature != null)
                _MetaChip(
                  icon: Icons.thermostat_outlined,
                  label: '${rec.temperature}°',
                ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    _ItemThumbnail(item: items[index]),
              ),
            ),
          ] else if (rec.clothingIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'These wardrobe items could not be loaded — try refreshing your wardrobe.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (rec.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(rec.reason, style: theme.textTheme.bodyMedium),
          ],
          if (_actionError != null) ...[
            const SizedBox(height: 8),
            Text(_actionError!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_actionSuccess != null) ...[
            const SizedBox(height: 8),
            Text(_actionSuccess!, style: const TextStyle(color: AppColors.green)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: _outfitId == null ? 'Save Outfit' : 'Saved',
                icon: Icons.bookmark_outline,
                loading: _isSaving,
                onPressed: items.isEmpty || _outfitId != null
                    ? null
                    : () => _ensureSaved(items),
              ),
              _ActionButton(
                label: 'Wear This',
                icon: Icons.checkroom_outlined,
                loading: _isWearing,
                onPressed: items.isEmpty ? null : () => _handleWear(items),
              ),
              _ActionButton(
                label: _favorite ? 'Favorited' : 'Favorite',
                icon: _favorite ? Icons.favorite : Icons.favorite_border,
                loading: _isFavoriting,
                onPressed: items.isEmpty ? null : () => _handleFavorite(items),
              ),
              _ActionButton(
                label: 'Schedule',
                icon: Icons.calendar_month_outlined,
                loading: _isScheduling,
                onPressed: items.isEmpty ? null : () => _handleSchedule(items),
              ),
              if (widget.onTryAnother != null)
                _ActionButton(
                  label: 'Try Another',
                  icon: Icons.refresh,
                  loading: false,
                  onPressed: widget.onTryAnother,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final num rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppGradients.cyanGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$rating/10',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      child: const Icon(Icons.checkroom_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.purple.withValues(alpha: 0.08),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
