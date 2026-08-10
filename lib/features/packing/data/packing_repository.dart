import 'package:closet_ai/core/services/api_client.dart';
import '../domain/packing_item.dart';

class PackingRepository {
  PackingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PackingItem>> fetchPacking(String tripId) async {
    final response = await _apiClient.get('/trips/$tripId/packing');
    final rawList = response['data'] as List<dynamic>? ?? [];
    return rawList
        .map(
          (item) =>
              PackingItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> generatePacking(String tripId) async {
    return _apiClient.post('/trips/$tripId/packing/generate');
  }

  Future<void> togglePacked(String tripId, String itemId) async {
    await _apiClient.put('/trips/$tripId/packing/$itemId/toggle');
  }

  Future<Map<String, dynamic>> regeneratePacking(String tripId) async {
    return _apiClient.post('/trips/$tripId/packing/regenerate');
  }
}
