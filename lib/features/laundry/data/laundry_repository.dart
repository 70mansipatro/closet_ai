import 'package:closet_ai/core/services/api_client.dart';

class LaundryRepository {
  LaundryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? color,
    String? brand,
    String? season,
    String? occasion,
    String? laundryStatus,
    String? sortBy = 'createdAt',
    String? sortOrder = 'desc',
  }) {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (color != null && color.isNotEmpty) 'color': color,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (season != null && season.isNotEmpty) 'season': season,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
      if (laundryStatus != null && laundryStatus.isNotEmpty)
        'laundryStatus': laundryStatus,
    };
    if (sortBy != null) {
      query['sortBy'] = sortBy;
    }
    if (sortOrder != null) {
      query['sortOrder'] = sortOrder;
    }
    return _apiClient.getWithQuery('/laundry', query: query);
  }

  Future<Map<String, dynamic>> fetchStatistics() {
    return _apiClient.get('/laundry/statistics');
  }

  Future<Map<String, dynamic>> updateStatus(
    String id,
    String newStatus, {
    String? method,
    String? notes,
  }) {
    final payload = <String, dynamic>{
      'newStatus': newStatus,
      if (method != null && method.isNotEmpty) 'method': method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    return _apiClient.put('/laundry/$id/status', data: payload);
  }
}
