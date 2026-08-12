import 'package:closet_ai/core/services/api_client.dart';
import '../domain/trip.dart';

class TripRepository {
  TripRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Trip>> fetchTrips({
    String? status,
    String? sortBy,
    String? sortOrder,
    int? limit,
    int? page,
  }) async {
    final query = <String, dynamic>{
      if (status != null) 'status': status,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (limit != null) 'limit': limit.toString(),
      if (page != null) 'page': page.toString(),
    };
    final response = query.isEmpty
        ? await _apiClient.get('/trips')
        : await _apiClient.getWithQuery('/trips', query: query);
    final rawList = response['data'] as List<dynamic>? ?? [];
    return rawList
        .map((item) => Trip.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Trip> createTrip(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/trips', data: payload);
    return Trip.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
