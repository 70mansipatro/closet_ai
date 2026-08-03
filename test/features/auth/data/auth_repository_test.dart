import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastData;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    lastData = data;
    return {'message': 'ok'};
  }
}

void main() {
  test('register sends only name, email, and password', () async {
    final apiClient = FakeApiClient();
    final repository = AuthRepository(apiClient);

    await repository.register({
      'name': 'abc',
      'email': 'abc@gmail.com',
      'password': 'Menutest@1234',
      'phone': '',
      'gender': 'prefer-not-to-say',
      'height': null,
      'weight': null,
      'preferredStyle': 'casual',
    });

    expect(apiClient.lastData, {
      'name': 'abc',
      'email': 'abc@gmail.com',
      'password': 'Menutest@1234',
    });
  });
}
