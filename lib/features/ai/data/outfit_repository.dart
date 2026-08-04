import 'package:closet_ai/core/services/api_client.dart';

class OutfitRepository {
  OutfitRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> generateOutfit({
    required String occasion,
    required String weather,
    required int temperature,
    required String season,
  }) {
    return _apiClient.post(
      '/outfits/generate',
      data: {
        'occasion': occasion,
        'weather': weather,
        'temperature': temperature,
        'season': season,
      },
    );
  }

  Future<Map<String, dynamic>> saveOutfit(Map<String, dynamic> payload) {
    return _apiClient.post('/outfits/save', data: payload);
  }

  Future<Map<String, dynamic>> wearOutfit(String outfitId) {
    return _apiClient.post('/outfits/wear', data: {'outfitId': outfitId});
  }

  Future<Map<String, dynamic>> fetchOutfits({bool? favorite}) {
    final query = <String, dynamic>{};
    if (favorite != null) {
      query['favorite'] = favorite.toString();
    }
    return _apiClient.get('/outfits${_buildQuery(query)}');
  }

  Future<Map<String, dynamic>> fetchOutfit(String id) {
    return _apiClient.get('/outfits/$id');
  }

  Future<Map<String, dynamic>> deleteOutfit(String id) {
    return _apiClient.delete('/outfits/$id');
  }

  Future<Map<String, dynamic>> toggleFavorite(
    String id, {
    required bool favorite,
  }) {
    return _apiClient.put(
      '/outfits/favorite',
      data: {'id': id, 'favorite': favorite},
    );
  }

  String _buildQuery(Map<String, dynamic> query) {
    final entries = query.entries
        .where((entry) => entry.value != null)
        .toList();
    if (entries.isEmpty) return '';
    final queryString = entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return '?$queryString';
  }
}
