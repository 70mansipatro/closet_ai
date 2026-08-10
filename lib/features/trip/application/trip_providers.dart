import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/trip_repository.dart';
import '../domain/trip.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

final tripListProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  final repository = ref.read(tripRepositoryProvider);
  return repository.fetchTrips();
});
