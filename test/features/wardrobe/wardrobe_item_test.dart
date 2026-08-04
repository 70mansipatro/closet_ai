import 'package:closet_ai/features/wardrobe/domain/wardrobe_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WardrobeItem parses a backend payload into a strongly typed model', () {
    final item = WardrobeItem.fromJson({
      '_id': 'abc123',
      'imageUrl': 'https://example.com/image.png',
      'category': 'shirt',
      'color': 'blue',
      'season': 'summer',
      'favorite': true,
      'laundryStatus': 'clean',
      'wearCount': '4',
      'lastWorn': '2025-01-01',
      'brand': 'Acme',
      'size': 'M',
      'occasion': 'casual',
      'notes': 'Soft cotton',
    });

    expect(item.id, 'abc123');
    expect(item.category, 'shirt');
    expect(item.favorite, isTrue);
    expect(item.wearCount, 4);
    expect(item.size, 'M');
    expect(item.notes, 'Soft cotton');
  });
}
