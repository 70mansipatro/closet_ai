import 'package:closet_ai/core/services/api_client.dart';

class CalendarRepository {
  CalendarRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> schedule({
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.post('/calendar/schedule', data: payload);
  }

  Future<Map<String, dynamic>> fetchCalendar({
    String? startDate,
    String? endDate,
  }) {
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    return _apiClient.getWithQuery('/calendar', query: query);
  }

  Future<Map<String, dynamic>> fetchByDate(String dateIso) {
    return _apiClient.get('/calendar/$dateIso');
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) {
    return _apiClient.put('/calendar/$id', data: payload);
  }

  Future<Map<String, dynamic>> delete(String id) {
    return _apiClient.delete('/calendar/$id');
  }

  Future<Map<String, dynamic>> wearToday({String? outfitId}) {
    return _apiClient.post(
      '/calendar/wear-today',
      data: {'outfitId': outfitId},
    );
  }
}
