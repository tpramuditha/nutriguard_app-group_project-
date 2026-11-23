import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nutriguard_app/features/food_scanner/data/repositories/food_repository.dart';

void main() {
  test('search returns foods with valid nutrition data', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'world.openfoodfacts.org');
      expect(request.url.queryParameters['search_terms'], 'oats');

      return http.Response(
        jsonEncode({
          'products': [
            {
              'code': '123456',
              'product_name': 'Test Oats',
              'brands': 'Example Brand',
              'nutriments': {
                'energy-kcal_100g': 380,
                'proteins_100g': 13,
                'carbohydrates_100g': 67,
                'fat_100g': 7,
              },
            },
          ],
        }),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final results = await repository.searchFoods('oats');

    expect(results.length, 1);
    expect(results.first.id, '123456');
    expect(results.first.name, 'Test Oats');
    expect(results.first.brand, 'Example Brand');
    expect(results.first.source, 'Open Food Facts');

    expect(results.first.caloriesPer100g, 380);
    expect(results.first.proteinPer100g, 13);
    expect(results.first.carbsPer100g, 67);
    expect(results.first.fatPer100g, 7);

    repository.dispose();
  });

  test('missing nutritional information is not treated as zero', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'code': '111',
              'product_name': 'Incomplete Food',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 3,
                'carbohydrates_100g': 20,
                // Fat is missing.
              },
            },
          ],
        }),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final results = await repository.searchFoods('food');

    expect(results, isEmpty);

    repository.dispose();
  });

  test('empty search returns no results without an API request', () async {
    var requestCount = 0;

    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{"products":[]}', 200);
    });

    final repository = FoodRepository(client: client);

    final results = await repository.searchFoods('   ');

    expect(results, isEmpty);
    expect(requestCount, 0);

    repository.dispose();
  });

  test('API errors are reported correctly', () async {
    final client = MockClient((request) async {
      return http.Response('Server Error', 500);
    });

    final repository = FoodRepository(client: client);

    await expectLater(
      repository.searchFoods('rice'),
      throwsA(isA<Exception>()),
    );

    repository.dispose();
  });

  test('nutrition values are converted to portion calculations', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'code': '789',
              'product_name': 'Example Rice',
              'nutriments': {
                'energy-kcal_100g': 130,
                'proteins_100g': 2.7,
                'carbohydrates_100g': 28.2,
                'fat_100g': 0.3,
              },
            },
          ],
        }),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final results = await repository.searchFoods('rice');

    expect(results.length, 1);

    final food = results.first;

    expect(food.caloriesForGrams(150), closeTo(195, 0.001));
    expect(food.proteinForGrams(150), closeTo(4.05, 0.001));
    expect(food.carbsForGrams(150), closeTo(42.3, 0.001));

    repository.dispose();
  });

  test('barcode lookup returns a valid food', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v2/product/1234567890123');

      return http.Response(
        jsonEncode({
          'status': 1,
          'product': {
            'code': '1234567890123',
            'product_name': 'Test Cereal',
            'brands': 'Example Brand',
            'nutriments': {
              'energy-kcal_100g': 380,
              'proteins_100g': 8,
              'carbohydrates_100g': 70,
              'fat_100g': 6,
            },
          },
        }),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final food = await repository.getFoodByBarcode('1234567890123');

    expect(food, isNotNull);
    expect(food!.name, 'Test Cereal');
    expect(food.brand, 'Example Brand');
    expect(food.source, 'Open Food Facts');
    expect(food.caloriesPer100g, 380);
    expect(food.proteinPer100g, 8);
    expect(food.carbsPer100g, 70);
    expect(food.fatPer100g, 6);

    repository.dispose();
  });

  test('unknown barcode returns null', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'status': 0, 'status_verbose': 'product not found'}),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final food = await repository.getFoodByBarcode('9999999999999');

    expect(food, isNull);

    repository.dispose();
  });

  test('barcode with incomplete nutrition returns null', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Incomplete Food',
            'nutriments': {
              'energy-kcal_100g': 120,
              'proteins_100g': 4,
              'carbohydrates_100g': 20,
              // Fat is missing.
            },
          },
        }),
        200,
      );
    });

    final repository = FoodRepository(client: client);

    final food = await repository.getFoodByBarcode('1234567890123');

    expect(food, isNull);

    repository.dispose();
  });

  test('invalid barcode does not call the API', () async {
    var requestCount = 0;

    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{}', 200);
    });

    final repository = FoodRepository(client: client);

    expect(await repository.getFoodByBarcode(''), isNull);
    expect(await repository.getFoodByBarcode('abc123'), isNull);
    expect(requestCount, 0);

    repository.dispose();
  });

  test('barcode lookup reports server errors', () async {
    final client = MockClient((request) async {
      return http.Response('Server Error', 500);
    });

    final repository = FoodRepository(client: client);

    await expectLater(
      repository.getFoodByBarcode('1234567890123'),
      throwsA(isA<Exception>()),
    );

    repository.dispose();
  });

  test('barcode lookup returns null for HTTP 404', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"status":0,"status_verbose":"product not found"}',
        404,
      );
    });

    final repository = FoodRepository(client: client);

    final food = await repository.getFoodByBarcode('1019566');

    expect(food, isNull);

    repository.dispose();
  });
}
