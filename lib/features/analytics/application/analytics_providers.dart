import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:closet_ai/core/services/api_client.dart';
import '../data/analytics_repository.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final analyticsRepositoryProvider = Provider(
  (ref) => AnalyticsRepository(ref.read(apiClientProvider)),
);

final analyticsFilterProvider = StateProvider<Map<String, String?>>(
  (ref) => {},
);

final analyticsOverviewProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getOverview(from: filters['from'], to: filters['to']);
});

final wardrobeAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getWardrobe();
});

final wearAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getWear(from: filters['from'], to: filters['to']);
});

final outfitAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getOutfits(from: filters['from'], to: filters['to']);
});

final categoryAnalyticsProvider = FutureProvider<List<dynamic>>((ref) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getCategories(from: filters['from'], to: filters['to']);
});

final colorAnalyticsProvider = FutureProvider<List<dynamic>>((ref) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getColors(from: filters['from'], to: filters['to']);
});

final brandAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getBrands(from: filters['from'], to: filters['to']);
});

final laundryAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getLaundry(from: filters['from'], to: filters['to']);
});

final costAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getCostPerWear();
});

final sustainabilityAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getSustainability(from: filters['from'], to: filters['to']);
});

final trendAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTrends(
    from: filters['from'],
    to: filters['to'],
    interval: filters['interval'] ?? 'monthly',
  );
});

final analyticsInsightsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final filters = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getInsights(from: filters['from'], to: filters['to']);
});
