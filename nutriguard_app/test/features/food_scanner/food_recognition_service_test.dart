import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

import 'package:nutriguard_app/features/food_scanner/data/services/food_recognition_service.dart';

void main() {
  late FoodRecognitionService service;
  late XFile testImage;

  setUp(() {
    service = FoodRecognitionService();

    // Small simulated JPEG for testing HTTP behavior.
    // No real photo is uploaded.
    testImage = XFile.fromData(
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      name: 'test_food.jpg',
      mimeType: 'image/jpeg',
    );
  });

  test('parses successful food recognition response', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/recognize-food');
      expect(request.headers['content-type'], contains('application/json'));

      return http.Response('''
        {
          "success": true,
          "foods": [
            {
              "name": "Kottu Roti",
              "alternative_names": ["Kottu"],
              "visible_ingredients": ["chopped roti"],
              "confidence": "high"
            },
            {
              "name": "Pol Sambol",
              "alternative_names": ["Coconut Sambol"],
              "visible_ingredients": ["coconut"],
              "confidence": "medium"
            }
          ],
          "uncertainties": []
        }
        ''', 200);
    });

    try {
      final result = await service.recognizeFood(testImage, client: client);

      expect(result.foods.length, 2);
      expect(result.foods.first.name, 'Kottu Roti');
      expect(result.foods.last.name, 'Pol Sambol');
      expect(result.foods.first.confidence, 'high');
    } finally {
      client.close();
    }
  });

  test('handles backend error response', () async {
    final client = MockClient((request) async {
      return http.Response('''
        {
          "success": false,
          "message": "Food recognition service unavailable."
        }
        ''', 502);
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'Food recognition service unavailable',
            ),
          ),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('handles invalid backend JSON', () async {
    final client = MockClient((request) async {
      return http.Response('invalid json', 200);
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('invalid response')),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('handles connection failure', () async {
    final client = MockClient((request) async {
      throw http.ClientException('Connection refused');
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('Cannot connect')),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('handles recognition timeout', () async {
    final client = MockClient((request) async {
      throw TimeoutException('Request timed out');
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('took too long')),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('rejects unsupported image format', () async {
    final invalidImage = XFile.fromData(
      Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
      name: 'not_food.pdf',
    );

    var requestMade = false;

    final client = MockClient((request) async {
      requestMade = true;
      return http.Response('{}', 200);
    });

    try {
      await expectLater(
        service.recognizeFood(invalidImage, client: client),
        throwsA(
          predicate(
            (error) => error.toString().contains('Unsupported image format'),
          ),
        ),
      );

      expect(requestMade, isFalse);
    } finally {
      client.close();
    }
  });

  test('rejects an oversized image before upload', () async {
    final oversizedImage = XFile.fromData(
      Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        ...List<int>.filled(3 * 1024 * 1024, 0),
      ]),
      name: 'large_food.jpg',
    );

    var requestMade = false;

    final client = MockClient((request) async {
      requestMade = true;
      return http.Response('{}', 200);
    });

    try {
      await expectLater(
        service.recognizeFood(oversizedImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('smaller than 3 MB')),
        ),
      );

      expect(requestMade, isFalse);
    } finally {
      client.close();
    }
  });

  test('rejects recognition response without foods list', () async {
    final client = MockClient((request) async {
      return http.Response('{"success":true,"uncertainties":[]}', 200);
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('invalid response')),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('rejects recognized food with empty name', () async {
    final client = MockClient((request) async {
      return http.Response('{"success":true,"foods":[{"name":""}]}', 200);
    });

    try {
      await expectLater(
        service.recognizeFood(testImage, client: client),
        throwsA(
          predicate((error) => error.toString().contains('invalid response')),
        ),
      );
    } finally {
      client.close();
    }
  });

  test('handles empty food recognition results', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"success":true,"foods":[],"uncertainties":[]}',
        200,
      );
    });

    try {
      final result = await service.recognizeFood(testImage, client: client);

      expect(result.foods, isEmpty);
      expect(result.uncertainties, isEmpty);
    } finally {
      client.close();
    }
  });
}
