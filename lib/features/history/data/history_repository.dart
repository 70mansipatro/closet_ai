import 'package:closet_ai/core/services/api_client.dart';

class HistoryRepository {
  HistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _apiClient.getWithQuery('/history', query: query);
  }

  Future<Map<String, dynamic>> clothingHistory(String id) {
    return _apiClient.get('/history/clothing/$id');
  }

  Future<Map<String, dynamic>> outfitHistory(String id) {
    return _apiClient.get('/history/outfit/$id');
  }

  Future<Map<String, dynamic>> stats() {
    return _apiClient.get('/history/stats');
  }
}
