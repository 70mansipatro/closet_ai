import 'package:closet_ai/core/services/api_client.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getOverview({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/overview',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getWardrobe() async {
    final response = await _apiClient.get('/analytics/wardrobe');
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getWear({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/wear',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOutfits({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/outfits',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<List<dynamic>> getCategories({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/categories',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return List<dynamic>.from(response['data'] as List<dynamic>);
  }

  Future<List<dynamic>> getColors({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/colors',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return List<dynamic>.from(response['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> getBrands({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/brands',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getLaundry({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/laundry',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getCostPerWear() async {
    final response = await _apiClient.get('/analytics/cost-per-wear');
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSustainability({
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/sustainability',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTrends({
    String interval = 'monthly',
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/trends',
      query: {
        'interval': interval,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getInsights({String? from, String? to}) async {
    final response = await _apiClient.getWithQuery(
      '/analytics/insights',
      query: {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);
  }
}
