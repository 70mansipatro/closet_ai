import 'package:closet_ai/features/trip/application/trip_providers.dart';
import 'package:closet_ai/features/trip/domain/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripPage extends ConsumerWidget {
  const TripPage({super.key});

  Future<void> _showCreateTripDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final destinationController = TextEditingController();
    final countryController = TextEditingController();
    final cityController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Trip name'),
                ),
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(labelText: 'Destination'),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start date (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End date (YYYY-MM-DD)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tripPayload = {
                  'tripName': nameController.text.trim(),
                  'destination': destinationController.text.trim(),
                  'country': countryController.text.trim(),
                  'city': cityController.text.trim(),
                  'startDate': startDateController.text.trim(),
                  'endDate': endDateController.text.trim(),
                };
                try {
                  await ref
                      .read(tripRepositoryProvider)
                      .createTrip(tripPayload);
                  ref.invalidate(tripListProvider);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to create trip: $error')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripTile(BuildContext context, Trip trip) {
    return Card(
      child: ListTile(
        title: Text(trip.tripName),
        subtitle: Text(
          '${trip.city}, ${trip.country}\n${trip.startDate.toIso8601String().split('T').first} — ${trip.endDate.toIso8601String().split('T').first}',
        ),
        isThreeLine: true,
        onTap: () {
          context.push('/packing/${trip.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(
              child: Text('No trips found yet. Tap + to add your first trip.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tripListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildTripTile(context, trips[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load trips: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTripDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
