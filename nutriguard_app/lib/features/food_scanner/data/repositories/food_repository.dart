import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_model.dart';

class FoodRepository {
  final http.Client _client;

  FoodRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<FoodModel>> searchFoods(String query) async {
    final searchTerm = query.trim();

    if (searchTerm.isEmpty) {
      return [];
    }

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': searchTerm,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': 'code,product_name,brands,nutriments',
    });

    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'NutriGuard/0.1 (student prototype)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    // Open Food Facts may return HTTP 404 for an unknown barcode.

    if (response.statusCode != 200) {
      throw Exception('Barcode lookup failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final products = data['products'];

    if (products is! List) {
      throw const FormatException('Invalid food search response.');
    }

    final foods = <FoodModel>[];

    for (final item in products) {
      if (item is! Map) continue;

      final product = Map<String, dynamic>.from(item);

      final id = product['code']?.toString() ?? '';
      final name = product['product_name']?.toString().trim() ?? '';

      final rawNutrients = product['nutriments'];

      if (id.isEmpty || name.isEmpty || rawNutrients is! Map) {
        continue;
      }

      final nutrients = Map<String, dynamic>.from(rawNutrients);

      double? readNutrient(String key) {
        final value = nutrients[key];

        if (value is num) {
          final number = value.toDouble();
          return number.isFinite && number >= 0 ? number : null;
        }

        return null;
      }

      final calories = readNutrient('energy-kcal_100g');
      final protein = readNutrient('proteins_100g');
      final carbs = readNutrient('carbohydrates_100g');
      final fat = readNutrient('fat_100g');

      // The current FoodModel requires all four
      // nutritional values. Do not assume missing
      // values are zero.
      if (calories == null || protein == null || carbs == null || fat == null) {
        continue;
      }

      final brand = product['brands']?.toString().trim();

      foods.add(
        FoodModel(
          id: id,
          name: name,
          brand: brand == null || brand.isEmpty ? null : brand,
          source: 'Open Food Facts',
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
        ),
      );
    }

    return foods;
  }

  Future<FoodModel?> getFoodByBarcode(String barcode) async {
    final code = barcode.trim();

    if (code.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(code)) {
      return null;
    }

    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$code', {
      'fields': 'code,product_name,brands,nutriments',
    });

    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'NutriGuard/0.1 (student prototype)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    // An unknown barcode can return HTTP 404.
    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Barcode lookup failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Open Food Facts uses status 0 when a product is not found.
    if (data['status'] != 1) {
      return null;
    }

    final rawProduct = data['product'];

    if (rawProduct is! Map) {
      return null;
    }

    final product = Map<String, dynamic>.from(rawProduct);

    final name = product['product_name']?.toString().trim() ?? '';

    final rawNutrients = product['nutriments'];

    if (name.isEmpty || rawNutrients is! Map) {
      return null;
    }

    final nutrients = Map<String, dynamic>.from(rawNutrients);

    double? readNutrient(String key) {
      final value = nutrients[key];

      if (value is! num) return null;

      final number = value.toDouble();

      if (!number.isFinite || number < 0) {
        return null;
      }

      return number;
    }

    final calories = readNutrient('energy-kcal_100g');
    final protein = readNutrient('proteins_100g');
    final carbs = readNutrient('carbohydrates_100g');
    final fat = readNutrient('fat_100g');

    // Do not replace missing nutrition values with zero.
    if (calories == null || protein == null || carbs == null || fat == null) {
      return null;
    }

    final brand = product['brands']?.toString().trim();

    return FoodModel(
      id: code,
      name: name,
      brand: brand == null || brand.isEmpty ? null : brand,
      source: 'Open Food Facts',
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
    );
  }

  void dispose() {
    _client.close();
  }
}
