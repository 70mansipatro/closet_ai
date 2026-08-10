import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/packing_repository.dart';
import '../domain/packing_item.dart';

final packingRepositoryProvider = Provider<PackingRepository>((ref) {
  return PackingRepository();
});

final packingListProvider = FutureProvider.family
    .autoDispose<List<PackingItem>, String>((ref, tripId) async {
      final repository = ref.read(packingRepositoryProvider);
      return repository.fetchPacking(tripId);
    });

final packingGenerateProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, tripId) async {
      final repository = ref.read(packingRepositoryProvider);
      return repository.generatePacking(tripId);
    });
