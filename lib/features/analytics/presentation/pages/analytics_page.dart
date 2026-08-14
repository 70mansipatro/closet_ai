import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:closet_ai/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/premium_feature_lock.dart';

import '../../../../core/layout/app_layout.dart';
import '../../application/analytics_providers.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/analytics_anim.dart';
import '../widgets/analytics_date_filter.dart';
import '../widgets/analytics_header.dart';
import '../widgets/analytics_hero_card.dart';
import '../widgets/analytics_kpi_card.dart';
import '../widgets/analytics_states.dart';
import '../widgets/category_analytics_card.dart';
import '../widgets/color_analytics_card.dart';
import '../widgets/cost_analytics_card.dart';
import '../widgets/laundry_analytics_card.dart';
import '../widgets/outfit_analytics_card.dart';
import '../../../admin/widgets/kpi_card.dart' show KpiGrid;
import '../widgets/wear_analytics_card.dart';

void _invalidateAllAnalytics(WidgetRef ref) {
  ref.invalidate(analyticsOverviewProvider);
  ref.invalidate(wearAnalyticsProvider);
  ref.invalidate(outfitAnalyticsProvider);
  ref.invalidate(categoryAnalyticsProvider);
  ref.invalidate(colorAnalyticsProvider);
  ref.invalidate(laundryAnalyticsProvider);
  ref.invalidate(costAnalyticsProvider);
  ref.invalidate(analyticsInsightsProvider);
}

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _dateFilter = 'this_month';
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyFilter('this_month');
    });
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to = now;

    switch (filter) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'this_week':
        final weekday = now.weekday;
        from = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        break;
      case 'this_month':
        from = DateTime(now.year, now.month, 1);
        break;
      case '30_days':
        from = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
      case '3_months':
        from = DateTime(now.year, now.month - 2, 1);
        break;
      case '6_months':
        from = DateTime(now.year, now.month - 5, 1);
        break;
      case 'this_year':
        from = DateTime(now.year, 1, 1);
        break;
      default:
        from = DateTime(now.year, now.month, 1);
    }

    ref.read(analyticsFilterProvider.notifier).state = {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'interval': filter == 'this_month' ? 'monthly' : 'weekly',
    };
    setState(() {
      _dateFilter = filter;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    _invalidateAllAnalytics(ref);
    // Give the invalidated FutureProviders a beat to start refetching before
    // clearing the header's spinner state.
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final wearAsync = ref.watch(wearAnalyticsProvider);
    final outfitAsync = ref.watch(outfitAnalyticsProvider);
    final categoryAsync = ref.watch(categoryAnalyticsProvider);
    final colorAsync = ref.watch(colorAnalyticsProvider);
    final laundryAsync = ref.watch(laundryAnalyticsProvider);
    final costAsync = ref.watch(costAnalyticsProvider);
    final insightAsync = ref.watch(analyticsInsightsProvider);

    final wardrobeCount = overviewAsync.value?['wardrobeCount'] as num?;
    final isEmptyWardrobe = overviewAsync.hasValue && (wardrobeCount ?? 0) == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomPadding(context)),
          children: [
            AnalyticsHeader(onRefresh: _handleRefresh, refreshing: _refreshing),
            const SizedBox(height: 16),
            if (isEmptyWardrobe)
              AnalyticsEmptyWardrobe(
                onAddClothing: () => context.push('/wardrobe/form'),
              )
            else ...[
            AnalyticsDateFilter(value: _dateFilter, onChanged: _applyFilter),
            const SizedBox(height: 20),
            FadeSlideIn(
              child: _combined3(
                overviewAsync,
                wearAsync,
                costAsync,
                skeletonHeight: 220,
                onRetry: () {
                  ref.invalidate(analyticsOverviewProvider);
                  ref.invalidate(wearAnalyticsProvider);
                  ref.invalidate(costAnalyticsProvider);
                },
                builder: (overview, wear, cost) =>
                    AnalyticsHeroCard(overview: overview, wear: wear, cost: cost),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _combined2(
                wearAsync,
                outfitAsync,
                skeletonHeight: 140,
                onRetry: () {
                  ref.invalidate(wearAnalyticsProvider);
                  ref.invalidate(outfitAnalyticsProvider);
                },
                builder: (wear, outfit) => KpiGrid(
                  cards: [
                    AnalyticsKpiCard(
                      label: 'Items Worn',
                      value: (wear['uniqueItemsWorn'] as num?) ?? 0,
                      icon: Icons.checkroom_outlined,
                      subtitle: 'Unique items worn',
                    ),
                    AnalyticsKpiCard(
                      label: 'Wear Frequency',
                      value: (wear['averageWearsPerItem'] as num?) ?? 0,
                      icon: Icons.repeat,
                      subtitle: 'Avg wears / item',
                      decimals: 1,
                    ),
                    AnalyticsKpiCard(
                      label: 'Outfits Worn',
                      value: (outfit['wornOutfits'] as num?) ?? 0,
                      icon: Icons.style_outlined,
                      subtitle: 'Total worn outfits',
                    ),
                    AnalyticsKpiCard(
                      label: 'Completion Rate',
                      value: (outfit['completionRate'] as num?) ?? 0,
                      icon: Icons.donut_large_outlined,
                      subtitle: 'Outfit completion',
                      suffix: '%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: ResponsiveTwoColumn(
                left: _section(
                  wearAsync,
                  skeletonHeight: 220,
                  onRetry: () => ref.invalidate(wearAnalyticsProvider),
                  builder: (wear) => WearAnalyticsCard(wear: wear),
                ),
                right: _section(
                  outfitAsync,
                  skeletonHeight: 220,
                  onRetry: () => ref.invalidate(outfitAnalyticsProvider),
                  builder: (outfit) => OutfitAnalyticsCard(outfit: outfit),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const PremiumFeatureLock(
              title: 'Unlock Advanced Style Intelligence ✨',
              subtitle:
                  'Get deeper wardrobe insights, outfit trends, cost efficiency and AI-powered recommendations.',
              buttonLabel: 'Upgrade to Premium',
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: ResponsiveTwoColumn(
                left: _section(
                  categoryAsync,
                  skeletonHeight: 260,
                  onRetry: () => ref.invalidate(categoryAnalyticsProvider),
                  builder: (categories) => CategoryAnalyticsCard(categories: categories),
                ),
                right: _section(
                  colorAsync,
                  skeletonHeight: 260,
                  onRetry: () => ref.invalidate(colorAnalyticsProvider),
                  builder: (colors) => ColorAnalyticsCard(colors: colors),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _section(
                laundryAsync,
                skeletonHeight: 200,
                onRetry: () => ref.invalidate(laundryAnalyticsProvider),
                builder: (laundry) => LaundryAnalyticsCard(laundry: laundry),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: _section(
                costAsync,
                skeletonHeight: 220,
                onRetry: () => ref.invalidate(costAnalyticsProvider),
                builder: (cost) => CostAnalyticsCard(cost: cost),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: _section(
                insightAsync,
                skeletonHeight: 220,
                onRetry: () => ref.invalidate(analyticsInsightsProvider),
                builder: (insight) => AIInsightsCard(insight: insight),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders one section's `.when()` as skeleton / error card / data widget —
/// shared plumbing so every analytics card gets the same premium
/// loading/error treatment instead of a bare spinner or a raw error string.
Widget _section<T>(
  AsyncValue<T> async, {
  required Widget Function(T data) builder,
  required VoidCallback onRetry,
  double skeletonHeight = 160,
}) {
  return async.when(
    data: builder,
    loading: () => AnalyticsSectionSkeleton(height: skeletonHeight),
    error: (error, stack) => AnalyticsErrorCard(onRetry: onRetry),
  );
}

/// Same as [_section] but combines two independent providers that a single
/// card needs together (e.g. the KPI grid needs both wear and outfit data).
Widget _combined2<A, B>(
  AsyncValue<A> a,
  AsyncValue<B> b, {
  required Widget Function(A a, B b) builder,
  required VoidCallback onRetry,
  double skeletonHeight = 160,
}) {
  if (a.hasError || b.hasError) {
    return AnalyticsErrorCard(onRetry: onRetry);
  }
  if (!a.hasValue || !b.hasValue) {
    return AnalyticsSectionSkeleton(height: skeletonHeight);
  }
  return builder(a.value as A, b.value as B);
}

/// Same as [_combined2] but for three providers (the hero card needs
/// overview + wear + cost together).
Widget _combined3<A, B, C>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  AsyncValue<C> c, {
  required Widget Function(A a, B b, C c) builder,
  required VoidCallback onRetry,
  double skeletonHeight = 160,
}) {
  if (a.hasError || b.hasError || c.hasError) {
    return AnalyticsErrorCard(onRetry: onRetry);
  }
  if (!a.hasValue || !b.hasValue || !c.hasValue) {
    return AnalyticsSectionSkeleton(height: skeletonHeight);
  }
  return builder(a.value as A, b.value as B, c.value as C);
}
