import 'package:closet_ai/core/services/api_client.dart';
import '../domain/trip.dart';

class TripRepository {
  TripRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Trip>> fetchTrips() async {
    final response = await _apiClient.get('/trips');
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
