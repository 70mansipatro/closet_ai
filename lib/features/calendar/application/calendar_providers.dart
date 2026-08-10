import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:closet_ai/features/calendar/data/calendar_repository.dart';
import 'package:closet_ai/core/services/api_client.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final calendarRepositoryProvider = Provider(
  (ref) => CalendarRepository(ref.read(apiClientProvider)),
);

final calendarByDateProvider =
    FutureProvider.family<Map<String, dynamic>?, DateTime>((ref, date) async {
      final repo = ref.read(calendarRepositoryProvider);
      final iso = date.toIso8601String();
      final resp = await repo.fetchByDate(iso);
      return resp['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp['data'] as Map)
          : null;
    });

final wearTodayActionProvider = Provider((ref) {
  final repo = ref.read(calendarRepositoryProvider);
  return (String? outfitId) async {
    final resp = await repo.wearToday(outfitId: outfitId);
    return resp;
  };
});
