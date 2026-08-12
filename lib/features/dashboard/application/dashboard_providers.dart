import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:closet_ai/features/calendar/application/calendar_providers.dart';
import 'package:closet_ai/features/packing/application/packing_providers.dart';
import 'package:closet_ai/features/packing/domain/packing_item.dart';
import 'package:closet_ai/features/trip/application/trip_providers.dart';
import 'package:closet_ai/features/trip/domain/trip.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>(
  (ref) => OutfitRepository(ApiClient()),
);

/// Total number of outfits the user has saved/generated so far.
final outfitsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(outfitRepositoryProvider);
  final response = await repo.fetchOutfits();
  final data = response['data'];
  return data is List ? data.length : 0;
});

DateTime _utcMidnight(DateTime date) => DateTime.utc(date.year, date.month, date.day);

/// Today's date normalized to UTC midnight — matches how the backend stores
/// calendar entry dates, so `calendarByDateProvider(todayUtcMidnight())`
/// reliably finds today's scheduled outfit.
DateTime todayUtcMidnight() => _utcMidnight(DateTime.now());

/// Planned (not yet worn) outfits scheduled for the next 14 days, soonest first.
final upcomingOutfitsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.read(calendarRepositoryProvider);
      final now = DateTime.now();
      final start = _utcMidnight(now.add(const Duration(days: 1)));
      final end = _utcMidnight(now.add(const Duration(days: 14)));
      final response = await repo.fetchCalendar(
        startDate: start.toIso8601String(),
        endDate: end.toIso8601String(),
      );
      final rawList = response['data'] as List<dynamic>? ?? [];
      final entries = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => (item['status'] ?? 'Planned') == 'Planned')
          .toList();
      entries.sort((a, b) {
        final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? now;
        final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? now;
        return dateA.compareTo(dateB);
      });
      return entries;
    });

/// The nearest upcoming trip, or null when none is scheduled.
final upcomingTripProvider = FutureProvider.autoDispose<Trip?>((ref) async {
  final repo = ref.read(tripRepositoryProvider);
  final trips = await repo.fetchTrips(
    status: 'upcoming',
    sortBy: 'startDate',
    sortOrder: 'asc',
    limit: 1,
  );
  return trips.isEmpty ? null : trips.first;
});

class PackingSummary {
  const PackingSummary({required this.trip, required this.remaining, required this.total});

  final Trip trip;
  final int remaining;
  final int total;
}

/// Packing progress for the nearest upcoming trip, or null when there's no
/// upcoming trip to pack for.
final packingSummaryProvider = FutureProvider.autoDispose<PackingSummary?>((
  ref,
) async {
  final trip = await ref.watch(upcomingTripProvider.future);
  if (trip == null) return null;

  final packingRepo = ref.read(packingRepositoryProvider);
  final List<PackingItem> items = await packingRepo.fetchPacking(trip.id);
  final remaining = items.where((item) => !item.packed).length;
  return PackingSummary(trip: trip, remaining: remaining, total: items.length);
});
