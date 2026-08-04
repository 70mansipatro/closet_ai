import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/ai/data/outfit_repository.dart';
import 'package:closet_ai/features/ai/presentation/pages/saved_outfits_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOutfitRepository extends OutfitRepository {
  FakeOutfitRepository() : super(FakeApiClient());

  @override
  Future<Map<String, dynamic>> fetchOutfits({bool? favorite}) async {
    return {'success': true, 'data': []};
  }
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super();
}

void main() {
  testWidgets('shows an empty state when no saved outfits are returned', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SavedOutfitsPage(repository: FakeOutfitRepository())),
    );

    await tester.pumpAndSettle();

    expect(find.text('No saved outfits yet.'), findsOneWidget);
  });
}
