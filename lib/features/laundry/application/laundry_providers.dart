import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:closet_ai/core/services/api_client.dart';
import '../data/laundry_repository.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final laundryRepositoryProvider = Provider(
  (ref) => LaundryRepository(ref.read(apiClientProvider)),
);

final laundryItemsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final repo = ref.read(laundryRepositoryProvider);
      final response = await repo.fetchItems(
        page: params['page'] as int? ?? 1,
        limit: params['limit'] as int? ?? 20,
        search: params['search'] as String?,
        category: params['category'] as String?,
        color: params['color'] as String?,
        brand: params['brand'] as String?,
        season: params['season'] as String?,
        occasion: params['occasion'] as String?,
        laundryStatus: params['laundryStatus'] as String?,
        sortBy: params['sortBy'] as String? ?? 'createdAt',
        sortOrder: params['sortOrder'] as String? ?? 'desc',
      );
      return response;
    });

final laundryStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(laundryRepositoryProvider);
  final response = await repo.fetchStatistics();
  return Map<String, dynamic>.from(response['data'] as Map);
});
