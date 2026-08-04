import 'dart:typed_data';

import 'package:closet_ai/features/wardrobe/data/wardrobe_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test(
    'createItem sends multipart form data when image bytes are provided',
    () async {
      final dio = Dio();
      RequestOptions? capturedOptions;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                data: {'success': true, 'data': {}},
                requestOptions: options,
                statusCode: 201,
              ),
            );
          },
        ),
      );

      final repository = WardrobeRepository(
        dio: dio,
        storage: const FlutterSecureStorage(),
      );

      await repository.createItem(
        payload: {'category': 'top', 'subCategory': 'T-shirt'},
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.contentType, contains('multipart/form-data'));
      expect(capturedOptions!.data, isA<FormData>());

      final formData = capturedOptions!.data as FormData;
      expect(formData.files, hasLength(1));
      expect(formData.files.first.key, 'image');
    },
  );
}
