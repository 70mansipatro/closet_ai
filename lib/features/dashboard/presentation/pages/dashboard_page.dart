import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:closet_ai/core/layout/app_layout.dart';
import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/core/theme/app_gradients.dart';
import 'package:closet_ai/features/analytics/application/analytics_providers.dart';
import 'package:closet_ai/features/auth/application/auth_state.dart';
import 'package:closet_ai/features/calendar/application/calendar_providers.dart';
import 'package:closet_ai/features/dashboard/application/dashboard_providers.dart';
import 'package:closet_ai/features/laundry/application/laundry_providers.dart';
import 'package:closet_ai/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/premium_banner.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:closet_ai/widgets/gradient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Timer? _greetingTicker;

  @override
  void initState() {
    super.initState();
    // Keeps the greeting band (morning/afternoon/evening/night) current if
    // the dashboard is left open across one of the time boundaries.
    _greetingTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _greetingTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [NotificationBell()],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomPadding(context)),
        children: [
          _GreetingHeader(user: user),
          const SizedBox(height: 16),
          const PremiumBanner(),
          const SizedBox(height: 4),
          const _QuickStatsGrid(),
          const SizedBox(height: 16),
          const _TodayOutfitCard(),
          const SizedBox(height: 16),
          const _UpcomingOutfitsCard(),
          const SizedBox(height: 16),
          const _LaundryReminderCard(),
          const SizedBox(height: 16),
          const _PackingCard(),
          const SizedBox(height: 16),
          const _WardrobeInsightCard(),
          const SizedBox(height: 16),
          const _AiStylistSuggestionCard(),
        ],
      ),
    );
  }
}

String _firstName(Map<String, dynamic>? user) {
  final name = (user?['name'] as String?)?.trim();
  if (name == null || name.isEmpty) return '';
  return name.split(RegExp(r'\s+')).first;
}

String _greeting(Map<String, dynamic>? user) {
  final firstName = _firstName(user);
  final hour = DateTime.now().hour;
  String band;
  if (hour >= 5 && hour < 12) {
    band = 'Good Morning';
  } else if (hour >= 12 && hour < 17) {
    band = 'Good Afternoon';
  } else if (hour >= 17 && hour < 21) {
    band = 'Good Evening';
  } else {
    band = 'Good Night';
  }
  return firstName.isEmpty ? '$band 👋' : '$band, $firstName 👋';
}

/// Dashboard header: greets the authenticated user by name (time-of-day band
/// derived from the device clock) alongside their real profile photo, or the
/// default avatar icon when none has been uploaded.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.user});

  final Map<String, dynamic>? user;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final photoUrl = user?['profileImage'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          child: ClipOval(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: textColor),
                    )
                  : Icon(Icons.person, color: textColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(user),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Here's your wardrobe overview",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2x2 grid of compact quick-stat tiles. Each tile watches its own provider
/// independently so a failure in one never blocks the others from rendering.
class _QuickStatsGrid extends ConsumerWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeCount = ref.watch(analyticsOverviewProvider).whenData(
      (data) => (data['wardrobeCount'] as num?)?.toInt() ?? 0,
    );
    final outfitsCount = ref.watch(outfitsCountProvider);
    final laundryCount = ref.watch(laundryStatisticsProvider).whenData(
      (data) => (data['dirty'] as num?)?.toInt() ?? 0,
    );
    final plannedCount = ref
        .watch(upcomingOutfitsProvider)
        .whenData((entries) => entries.length);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          icon: Icons.checkroom_outlined,
          accentColor: AppColors.cyan,
          label: 'Total Clothes',
          value: wardrobeCount,
          onTap: () => context.go('/wardrobe'),
        ),
        _StatCard(
          icon: Icons.auto_awesome_outlined,
          accentColor: AppColors.purple,
          label: 'Outfits',
          value: outfitsCount,
          onTap: () => context.go('/ai/saved'),
        ),
        _StatCard(
          icon: Icons.local_laundry_service_outlined,
          accentColor: AppColors.orange,
          label: 'Laundry',
          value: laundryCount,
          onTap: () => context.go('/laundry'),
        ),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          accentColor: AppColors.blue,
          label: 'Planned',
          value: plannedCount,
          onTap: () => context.go('/calendar'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String label;
  final AsyncValue<int> value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GlassCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                value.when(
                  data: (count) => Text(
                    '$count',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => Text(
                    '0',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Human-readable summary of a calendar entry's outfit — prefers the linked
/// Outfit's descriptive text fields, falling back to the populated clothing
/// items, then the calendar entry's own weather/occasion fields.
class _OutfitDisplay {
  const _OutfitDisplay({
    this.top,
    this.bottom,
    this.footwear,
    required this.occasion,
    this.weather,
    this.temperature,
  });

  final String? top;
  final String? bottom;
  final String? footwear;
  final String occasion;
  final String? weather;
  final int? temperature;

  bool get hasItems => top != null || bottom != null || footwear != null;
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String? _stringOrNull(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _clothingLabel(dynamic item) {
  if (item is! Map) return null;
  final color = _stringOrNull(item['color']);
  final subCategory = _stringOrNull(item['subCategory']);
  final category = subCategory ?? _stringOrNull(item['category']);
  if (category == null) return null;
  final label = _capitalize(category);
  return color != null ? '${_capitalize(color)} $label' : label;
}

_OutfitDisplay _extractOutfit(Map<String, dynamic> entry) {
  final outfit = entry['outfit'] as Map<String, dynamic>?;
  return _OutfitDisplay(
    top: _stringOrNull(outfit?['top']) ?? _clothingLabel(entry['topItem']),
    bottom:
        _stringOrNull(outfit?['bottom']) ?? _clothingLabel(entry['bottomItem']),
    footwear: _stringOrNull(outfit?['footwear']) ??
        _clothingLabel(entry['footwearItem']),
    occasion: _stringOrNull(outfit?['occasion']) ??
        _stringOrNull(entry['occasion']) ??
        'casual',
    weather: _stringOrNull(outfit?['weather']) ?? _stringOrNull(entry['weather']),
    temperature: (outfit?['temperature'] as num?)?.toInt() ??
        (entry['temperature'] as num?)?.toInt(),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.onViewMore,
    this.viewMoreLabel,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onViewMore;
  final String? viewMoreLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
            if (onViewMore != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onViewMore,
                  child: Text(viewMoreLabel ?? 'View more →'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Today's AI-recommended outfit, sourced from the existing outfit calendar.
class _TodayOutfitCard extends ConsumerWidget {
  const _TodayOutfitCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = todayUtcMidnight();
    final entryAsync = ref.watch(calendarByDateProvider(today));

    return entryAsync.when(
      loading: () => const GradientCard(
        gradient: AppGradients.primary,
        child: Center(child: _InlineLoader()),
      ),
      error: (_, _) => const _GetRecommendationCard(),
      data: (entry) {
        if (entry == null || entry['status'] == 'Skipped') {
          return const _GetRecommendationCard();
        }

        final outfit = _extractOutfit(entry);
        final outfitId = entry['outfitId']?.toString();

        return GradientCard(
          gradient: AppGradients.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "Today's AI Outfit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (outfit.hasItems) ...[
                if (outfit.top != null) _OutfitLine('Top', outfit.top!),
                if (outfit.bottom != null) _OutfitLine('Bottom', outfit.bottom!),
                if (outfit.footwear != null)
                  _OutfitLine('Footwear', outfit.footwear!),
              ] else
                const Text(
                  'Outfit planned for today',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 4),
              Text(
                outfit.temperature != null
                    ? '${_capitalize(outfit.occasion)} • ${outfit.temperature}°C'
                    : _capitalize(outfit.occasion),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Wear This Outfit',
                icon: Icons.checkroom_rounded,
                variant: GradientButtonVariant.success,
                onPressed: () async {
                  final wear = ref.read(wearTodayActionProvider);
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  try {
                    await wear(outfitId);
                    ref.invalidate(calendarByDateProvider(today));
                    ref.invalidate(analyticsOverviewProvider);
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('Marked as worn')),
                    );
                  } catch (error) {
                    messenger?.showSnackBar(
                      SnackBar(content: Text('Failed: $error')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutfitLine extends StatelessWidget {
  const _OutfitLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _GetRecommendationCard extends StatelessWidget {
  const _GetRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.primary,
      onTap: () => context.go('/ai/stylist'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's AI Outfit",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get AI Recommendation',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}

String _relativeDayLabel(DateTime date) {
  final target = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(target.year, target.month, target.day);
  final diff = targetDay.difference(today).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff < 7) return 'In $diff days';
  return DateFormat('EEE, d MMM').format(target);
}

/// Nearest planned outfits from the existing Outfit Calendar.
class _UpcomingOutfitsCard extends ConsumerWidget {
  const _UpcomingOutfitsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingOutfitsProvider);

    return _SectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Upcoming Outfits',
      onViewMore: () => context.go('/calendar'),
      viewMoreLabel: 'View Calendar →',
      child: upcomingAsync.when(
        loading: () => const _InlineLoader(),
        error: (_, _) => const Text('No upcoming outfits planned'),
        data: (entries) {
          if (entries.isEmpty) {
            return const Text('No upcoming outfits planned');
          }
          final entry = entries.first;
          final date = DateTime.tryParse(entry['date']?.toString() ?? '');
          final outfit = _extractOutfit(entry);
          final preview = [outfit.top, outfit.bottom, outfit.footwear]
              .whereType<String>()
              .join(' • ');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date != null ? _relativeDayLabel(date) : 'Upcoming'} • ${_capitalize(outfit.occasion)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(preview, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Laundry status summary, sourced from the existing Laundry module.
class _LaundryReminderCard extends ConsumerWidget {
  const _LaundryReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(laundryStatisticsProvider);

    return _SectionCard(
      icon: Icons.local_laundry_service_outlined,
      title: 'Laundry Reminder',
      onViewMore: () => context.go('/laundry'),
      viewMoreLabel: 'View Laundry →',
      child: statsAsync.when(
        loading: () => const _InlineLoader(),
        error: (_, _) => const Text('0 items need attention'),
        data: (data) {
          final dirty = (data['dirty'] as num?)?.toInt() ?? 0;
          return Text(
            dirty == 0
                ? 'All clothes are clean'
                : '$dirty item${dirty == 1 ? '' : 's'} need attention',
          );
        },
      ),
    );
  }
}

/// Packing progress for the nearest upcoming trip, sourced from the existing
/// Trip/Packing module.
class _PackingCard extends ConsumerWidget {
  const _PackingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(packingSummaryProvider);

    return _SectionCard(
      icon: Icons.flight_takeoff_outlined,
      title: 'Packing List',
      onViewMore: summaryAsync.maybeWhen(
        data: (summary) =>
            summary != null ? () => context.go('/packing/${summary.trip.id}') : null,
        orElse: () => null,
      ),
      viewMoreLabel: 'View Packing →',
      child: summaryAsync.when(
        loading: () => const _InlineLoader(),
        error: (_, _) => const Text('No upcoming trips'),
        data: (summary) {
          if (summary == null) {
            return const Text('No upcoming trips');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.trip.tripName.isEmpty
                    ? summary.trip.destination
                    : summary.trip.tripName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.remaining == 0
                    ? 'All items packed'
                    : '${summary.remaining} of ${summary.total} items remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact analytics summary, sourced from the existing Analytics module.
class _WardrobeInsightCard extends ConsumerWidget {
  const _WardrobeInsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryAnalyticsProvider);
    final insightsAsync = ref.watch(analyticsInsightsProvider);

    return _SectionCard(
      icon: Icons.insights_outlined,
      title: 'Wardrobe Insight',
      onViewMore: () => context.go('/analytics'),
      viewMoreLabel: 'View Analytics →',
      child: categoryAsync.when(
        loading: () => const _InlineLoader(),
        error: (_, _) => insightsAsync.maybeWhen(
          data: (data) => Text(_stringOrNull(data['summary']) ?? _genericInsight),
          orElse: () => const Text(_genericInsight),
        ),
        data: (categories) {
          if (categories.isNotEmpty) {
            final top = categories.first as Map;
            final category = _stringOrNull(top['category']) ??
                _stringOrNull(top['label']) ??
                _stringOrNull(top['name']);
            if (category != null) {
              return Text('Your most worn category is ${_capitalize(category)}');
            }
          }
          return insightsAsync.maybeWhen(
            data: (data) => Text(_stringOrNull(data['summary']) ?? _genericInsight),
            orElse: () => const Text(_genericInsight),
          );
        },
      ),
    );
  }
}

const _genericInsight = 'Wear more of your wardrobe to see personalized insights here.';

/// Lightweight AI stylist nudge — reuses the same today's-calendar data as
/// the "Today's AI Outfit" card (Riverpod dedupes the request) but frames it
/// as a suggestion, distinct from that card's "mark as worn" action.
class _AiStylistSuggestionCard extends ConsumerWidget {
  const _AiStylistSuggestionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(calendarByDateProvider(todayUtcMidnight()));

    return GlassCard(
      accentColor: AppColors.deepPurple,
      onTap: () => context.go('/ai/stylist'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.deepPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Stylist Suggestion',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                entryAsync.when(
                  loading: () => const _InlineLoader(),
                  error: (_, _) => const Text('Get a personalized outfit recommendation.'),
                  data: (entry) {
                    if (entry == null) {
                      return const Text('Get a personalized outfit recommendation.');
                    }
                    final outfit = _extractOutfit(entry);
                    if (outfit.top == null && outfit.bottom == null) {
                      return const Text('Get a personalized outfit recommendation.');
                    }
                    final suggestion = outfit.top != null && outfit.bottom != null
                        ? 'Try ${outfit.top} with ${outfit.bottom}.'
                        : 'Try ${outfit.top ?? outfit.bottom}.';
                    return Text(
                      outfit.temperature != null
                          ? "It's ${outfit.temperature}°C today. $suggestion"
                          : suggestion,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
