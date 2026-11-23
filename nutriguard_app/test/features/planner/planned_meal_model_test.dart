import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/planner/data/models/planned_meal_model.dart';

void main() {
  const validMeal = PlannedMealModel(
    id: 'meal_001',
    date: '2026-11-08',
    mealType: 'Lunch',
    recipeId: 'egg_fried_rice',
    servings: 2,
  );

  group('PlannedMealModel', () {
    test('accepts a valid planned meal', () {
      expect(() => validMeal.validate(), returnsNormally);
    });

    test('supports four meal types', () {
      expect(PlannedMealModel.validMealTypes, [
        'Breakfast',
        'Lunch',
        'Dinner',
        'Snack',
      ]);
    });

    test('converts model to Firestore map', () {
      final map = validMeal.toMap();

      expect(map['id'], 'meal_001');
      expect(map['date'], '2026-11-08');
      expect(map['mealType'], 'Lunch');
      expect(map['recipeId'], 'egg_fried_rice');
      expect(map['servings'], 2);
    });

    test('creates model from Firestore map', () {
      final model = PlannedMealModel.fromMap({
        'id': 'meal_002',
        'date': '2026-11-09',
        'mealType': 'Dinner',
        'recipeId': 'rice_and_dhal',
        'servings': 1,
      });

      expect(model.id, 'meal_002');
      expect(model.date, '2026-11-09');
      expect(model.mealType, 'Dinner');
      expect(model.recipeId, 'rice_and_dhal');
      expect(model.servings, 1);
    });

    test('supports map round-trip', () {
      final restored = PlannedMealModel.fromMap(validMeal.toMap());

      expect(restored.id, validMeal.id);
      expect(restored.date, validMeal.date);
      expect(restored.mealType, validMeal.mealType);
      expect(restored.recipeId, validMeal.recipeId);
      expect(restored.servings, validMeal.servings);
    });

    test('copyWith updates servings', () {
      final updated = validMeal.copyWith(servings: 3);

      expect(updated.servings, 3);
      expect(updated.id, validMeal.id);
      expect(updated.recipeId, validMeal.recipeId);
    });

    test('copyWith updates meal type and date', () {
      final updated = validMeal.copyWith(
        mealType: 'Dinner',
        date: '2026-11-10',
      );

      expect(updated.mealType, 'Dinner');
      expect(updated.date, '2026-11-10');
      expect(updated.servings, 2);
    });

    test('rejects empty meal ID', () {
      expect(() => validMeal.copyWith(id: ''), throwsArgumentError);
    });

    test('rejects invalid meal type', () {
      expect(() => validMeal.copyWith(mealType: 'Brunch'), throwsArgumentError);
    });

    test('rejects empty recipe ID', () {
      expect(() => validMeal.copyWith(recipeId: ''), throwsArgumentError);
    });

    test('rejects zero servings', () {
      expect(() => validMeal.copyWith(servings: 0), throwsArgumentError);
    });

    test('rejects more than 20 servings', () {
      expect(() => validMeal.copyWith(servings: 21), throwsArgumentError);
    });

    test('accepts minimum one serving', () {
      expect(() => validMeal.copyWith(servings: 1), returnsNormally);
    });

    test('accepts maximum twenty servings', () {
      expect(() => validMeal.copyWith(servings: 20), returnsNormally);
    });

    test('rejects invalid date format', () {
      expect(() => validMeal.copyWith(date: '08-11-2026'), throwsArgumentError);
    });

    test('rejects impossible calendar date', () {
      expect(() => validMeal.copyWith(date: '2026-02-30'), throwsArgumentError);
    });

    test('rejects month thirteen', () {
      expect(() => validMeal.copyWith(date: '2026-13-01'), throwsArgumentError);
    });

    test('accepts valid leap day', () {
      expect(() => validMeal.copyWith(date: '2028-02-29'), returnsNormally);
    });

    test('formats dates as yyyy-MM-dd', () {
      expect(PlannedMealModel.formatDate(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('rejects malformed Firestore data', () {
      expect(
        () => PlannedMealModel.fromMap({
          'id': 'meal_003',
          'date': 'invalid',
          'mealType': 'Lunch',
          'recipeId': 'boiled_eggs',
          'servings': 2,
        }),
        throwsArgumentError,
      );
    });
  });
}
