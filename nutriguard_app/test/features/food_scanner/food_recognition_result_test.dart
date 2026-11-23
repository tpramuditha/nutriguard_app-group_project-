import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/food_scanner/data/models/food_recognition_result.dart';

void main() {
  const sampleResponse = '''
{
  "foods": [
    {
      "name": "Hoppers",
      "alternative_names": [
        "Appa",
        "Egg Hoppers",
        "Egg Appa"
      ],
      "visible_ingredients": [
        "fermented rice batter",
        "egg"
      ],
      "confidence": "high"
    },
    {
      "name": "Chili Paste",
      "alternative_names": [
        "Chili Curry",
        "Lukumpittu"
      ],
      "visible_ingredients": [
        "chilies",
        "oil",
        "spices"
      ],
      "confidence": "medium"
    },
    {
      "name": "Watermelon",
      "alternative_names": [],
      "visible_ingredients": [
        "watermelon flesh"
      ],
      "confidence": "high"
    },
    {
      "name": "Sambol",
      "alternative_names": [
        "Coconut Sambol",
        "Kiriya Sambol"
      ],
      "visible_ingredients": [
        "coconut",
        "oil"
      ],
      "confidence": "low"
    }
  ],
  "uncertainties": [
    "The specific type of sambol is difficult to determine.",
    "The composition of the red side dish is unclear."
  ]
}
''';

  test('parses four recognized foods from Groq JSON', () {
    final result = FoodRecognitionResult.fromJsonString(sampleResponse);

    expect(result.foods.length, 4);
    expect(result.foods[0].name, 'Hoppers');
    expect(result.foods[1].name, 'Chili Paste');
    expect(result.foods[2].name, 'Watermelon');
    expect(result.foods[3].name, 'Sambol');
  });

  test('preserves alternative food names', () {
    final result = FoodRecognitionResult.fromJsonString(sampleResponse);

    expect(result.foods.first.alternativeNames, contains('Egg Hoppers'));
    expect(result.foods.first.alternativeNames, contains('Appa'));
  });

  test('preserves confidence levels', () {
    final result = FoodRecognitionResult.fromJsonString(sampleResponse);

    expect(result.foods[0].confidence, 'high');
    expect(result.foods[1].confidence, 'medium');
    expect(result.foods[3].confidence, 'low');
  });

  test('preserves uncertainties', () {
    final result = FoodRecognitionResult.fromJsonString(sampleResponse);

    expect(result.uncertainties.length, 2);
    expect(result.uncertainties.first, contains('sambol'));
  });

  test('converts recognition result back into JSON', () {
    final result = FoodRecognitionResult.fromJsonString(sampleResponse);

    final encoded = jsonEncode(result.toJson());
    final restored = FoodRecognitionResult.fromJsonString(encoded);

    expect(restored.foods.length, 4);
    expect(restored.foods.first.name, 'Hoppers');
    expect(restored.uncertainties.length, 2);
  });

  test('rejects JSON without a foods list', () {
    expect(
      () => FoodRecognitionResult.fromJsonString('{"uncertainties":[]}'),
      throwsFormatException,
    );
  });

  test('rejects recognized food without a name', () {
    expect(
      () => FoodRecognitionResult.fromJsonString(
        '{"foods":[{"name":"","confidence":"high"}]}',
      ),
      throwsFormatException,
    );
  });

  test('handles unknown confidence safely', () {
    final result = FoodRecognitionResult.fromJsonString(
      '{"foods":[{"name":"Rice","confidence":"certain"}]}',
    );

    expect(result.foods.first.confidence, 'unknown');
  });

  test('handles missing optional fields', () {
    final result = FoodRecognitionResult.fromJsonString(
      '{"foods":[{"name":"Rice"}]}',
    );

    expect(result.foods.first.alternativeNames, isEmpty);
    expect(result.foods.first.visibleIngredients, isEmpty);
    expect(result.uncertainties, isEmpty);
  });

  test('rejects invalid JSON', () {
    expect(
      () => FoodRecognitionResult.fromJsonString('not json'),
      throwsFormatException,
    );
  });
}
