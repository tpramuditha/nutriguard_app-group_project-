import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';

void main() {
  final testDate = DateTime.utc(2026, 11, 3, 8, 30);

  FoodLogModel createFoodLog({String? imagePath}) {
    return FoodLogModel(
      foodId: 'food_001',
      foodName: 'Rice and Dhal',
      brand: null,
      source: 'Manual',
      grams: 150,
      mealType: 'Breakfast',
      calories: 250,
      protein: 8,
      carbs: 45,
      fat: 4,
      loggedAt: testDate,
      localImagePath: imagePath,
    );
  }

  Map<String, dynamic> oldFoodLogMap() {
    return {
      'foodId': 'food_001',
      'foodName': 'Rice and Dhal',
      'brand': null,
      'source': 'Manual',
      'grams': 150.0,
      'mealType': 'Breakfast',
      'calories': 250.0,
      'protein': 8.0,
      'carbs': 45.0,
      'fat': 4.0,
      'loggedAt': Timestamp.fromDate(testDate),
    };
  }

  group('FoodLogModel image support', () {
    test('loads old Firestore food logs without an image field', () {
      final foodLog = FoodLogModel.fromMap(oldFoodLogMap());

      expect(foodLog.foodName, 'Rice and Dhal');
      expect(foodLog.localImagePath, isNull);
    });

    test('does not write an image field when photo is absent', () {
      final foodLog = createFoodLog();

      final map = foodLog.toMap();

      expect(map.containsKey('localImagePath'), isFalse);
    });

    test('does not upload local image paths to Firestore', () {
      final foodLog = createFoodLog(imagePath: '/app/food_images/meal.jpg');

      final map = foodLog.toMap();

      expect(map.containsKey('localImagePath'), isFalse);
    });

    test('restores the saved image path from a map', () {
      final map = oldFoodLogMap();

      map['localImagePath'] = '/app/food_images/meal.jpg';

      final foodLog = FoodLogModel.fromMap(map);

      expect(foodLog.localImagePath, '/app/food_images/meal.jpg');
    });

    test('treats an empty image path as absent', () {
      final map = oldFoodLogMap();

      map['localImagePath'] = '';

      final foodLog = FoodLogModel.fromMap(map);

      expect(foodLog.localImagePath, isNull);
    });

    test('ignores image path values with invalid types', () {
      final map = oldFoodLogMap();

      map['localImagePath'] = 12345;

      final foodLog = FoodLogModel.fromMap(map);

      expect(foodLog.localImagePath, isNull);
    });

    test('omits whitespace-only image paths from toMap', () {
      final foodLog = createFoodLog(imagePath: '   ');

      final map = foodLog.toMap();

      expect(map.containsKey('localImagePath'), isFalse);
    });

    test('preserves nutrition data after serialization', () {
      final original = createFoodLog(imagePath: '/app/food_images/meal.jpg');

      final restored = FoodLogModel.fromMap(original.toMap());

      expect(restored.foodId, original.foodId);
      expect(restored.foodName, original.foodName);
      expect(restored.grams, original.grams);
      expect(restored.mealType, original.mealType);
      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
      expect(restored.loggedAt.isAtSameMomentAs(original.loggedAt), isTrue);
      expect(restored.localImagePath, isNull);
      expect(original.localImagePath, '/app/food_images/meal.jpg');
    });
  });
}
