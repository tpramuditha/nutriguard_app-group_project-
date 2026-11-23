import 'dart:convert';

class RecognizedFood {
  final String name;
  final List<String> alternativeNames;
  final List<String> visibleIngredients;
  final String confidence;

  const RecognizedFood({
    required this.name,
    required this.alternativeNames,
    required this.visibleIngredients,
    required this.confidence,
  });

  factory RecognizedFood.fromJson(Map<String, dynamic> json) {
    final name = json['name'];

    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid recognized food name.');
    }

    List<String> readStrings(dynamic value) {
      if (value is! List) return [];

      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final rawConfidence = json['confidence']?.toString().toLowerCase().trim();

    final confidence = ['high', 'medium', 'low'].contains(rawConfidence)
        ? rawConfidence!
        : 'unknown';

    return RecognizedFood(
      name: name.trim(),
      alternativeNames: readStrings(json['alternative_names']),
      visibleIngredients: readStrings(json['visible_ingredients']),
      confidence: confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'alternative_names': alternativeNames,
      'visible_ingredients': visibleIngredients,
      'confidence': confidence,
    };
  }
}

class FoodRecognitionResult {
  final List<RecognizedFood> foods;
  final List<String> uncertainties;

  const FoodRecognitionResult({
    required this.foods,
    required this.uncertainties,
  });

  factory FoodRecognitionResult.fromJson(Map<String, dynamic> json) {
    final rawFoods = json['foods'];

    if (rawFoods is! List) {
      throw const FormatException('Invalid food recognition response.');
    }

    final foods = rawFoods.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid food recognition item.');
      }

      return RecognizedFood.fromJson(item);
    }).toList();

    final rawUncertainties = json['uncertainties'];

    final uncertainties = rawUncertainties is List
        ? rawUncertainties
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    return FoodRecognitionResult(foods: foods, uncertainties: uncertainties);
  }

  factory FoodRecognitionResult.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Recognition result must be a JSON object.');
    }

    return FoodRecognitionResult.fromJson(decoded);
  }

  Map<String, dynamic> toJson() {
    return {
      'foods': foods.map((food) => food.toJson()).toList(),
      'uncertainties': uncertainties,
    };
  }
}
