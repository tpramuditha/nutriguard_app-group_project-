import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/planner/data/models/planned_meal_model.dart';
import 'package:nutriguard_app/features/planner/data/repositories/meal_plan_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MealPlanRepository repository;

  const userId = 'test_user_001';

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = MealPlanRepository(firestore: firestore);
  });

  Future<PlannedMealModel> createTestMeal({
    String userId = userId,
    String date = '2026-11-08',
    String mealType = 'Lunch',
    String recipeId = 'egg_fried_rice',
    int servings = 2,
  }) {
    return repository.createMeal(
      userId: userId,
      date: date,
      mealType: mealType,
      recipeId: recipeId,
      servings: servings,
    );
  }

  group('MealPlanRepository', () {
    test('creates a meal in Firestore', () async {
      final meal = await createTestMeal();

      expect(meal.id, isNotEmpty);
      expect(meal.date, '2026-11-08');
      expect(meal.mealType, 'Lunch');
      expect(meal.recipeId, 'egg_fried_rice');
      expect(meal.servings, 2);

      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('plannedMeals')
          .doc(meal.id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['servings'], 2);
    });

    test('retrieves an existing meal', () async {
      final created = await createTestMeal();

      final retrieved = await repository.getMeal(
        userId: userId,
        mealId: created.id,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.recipeId, 'egg_fried_rice');
    });

    test('returns null for unknown meal', () async {
      final meal = await repository.getMeal(
        userId: userId,
        mealId: 'unknown_meal',
      );

      expect(meal, isNull);
    });

    test('updates an existing meal', () async {
      final created = await createTestMeal();

      final updated = created.copyWith(servings: 3, recipeId: 'rice_and_dhal');

      await repository.updateMeal(userId: userId, meal: updated);

      final saved = await repository.getMeal(
        userId: userId,
        mealId: created.id,
      );

      expect(saved!.servings, 3);
      expect(saved.recipeId, 'rice_and_dhal');
    });

    test('deletes an existing meal', () async {
      final created = await createTestMeal();

      await repository.deleteMeal(userId: userId, mealId: created.id);

      final deleted = await repository.getMeal(
        userId: userId,
        mealId: created.id,
      );

      expect(deleted, isNull);
    });

    test('watches meals for a selected date', () async {
      await createTestMeal(
        date: '2026-11-08',
        mealType: 'Breakfast',
        recipeId: 'boiled_eggs',
      );

      await createTestMeal(date: '2026-11-08', mealType: 'Lunch');

      await createTestMeal(date: '2026-11-09', mealType: 'Dinner');

      final meals = await repository
          .watchMealsForDate(userId: userId, date: '2026-11-08')
          .first;

      expect(meals.length, 2);
      expect(meals.every((meal) => meal.date == '2026-11-08'), isTrue);
    });

    test('watches meals within a weekly date range', () async {
      await createTestMeal(date: '2026-11-08');
      await createTestMeal(date: '2026-11-10');
      await createTestMeal(date: '2026-11-15');

      final meals = await repository
          .watchMealsForRange(
            userId: userId,
            startDate: '2026-11-08',
            endDate: '2026-11-14',
          )
          .first;

      expect(meals.length, 2);
      expect(
        meals.map((meal) => meal.date),
        containsAll(['2026-11-08', '2026-11-10']),
      );
    });

    test('orders meals by date and meal type', () async {
      await createTestMeal(date: '2026-11-09', mealType: 'Dinner');

      await createTestMeal(date: '2026-11-08', mealType: 'Lunch');

      await createTestMeal(date: '2026-11-08', mealType: 'Breakfast');

      final meals = await repository
          .watchMealsForRange(
            userId: userId,
            startDate: '2026-11-08',
            endDate: '2026-11-09',
          )
          .first;

      expect(meals.map((meal) => meal.mealType).toList(), [
        'Breakfast',
        'Lunch',
        'Dinner',
      ]);
    });

    test('stores different users meals separately', () async {
      await createTestMeal(userId: 'user_a', recipeId: 'boiled_eggs');

      await createTestMeal(userId: 'user_b', recipeId: 'egg_fried_rice');

      final userAMeals = await repository
          .watchMealsForDate(userId: 'user_a', date: '2026-11-08')
          .first;

      final userBMeals = await repository
          .watchMealsForDate(userId: 'user_b', date: '2026-11-08')
          .first;

      expect(userAMeals.length, 1);
      expect(userBMeals.length, 1);
      expect(userAMeals.first.recipeId, 'boiled_eggs');
      expect(userBMeals.first.recipeId, 'egg_fried_rice');
    });

    test('rejects invalid planned servings', () async {
      await expectLater(createTestMeal(servings: 0), throwsArgumentError);
    });

    test('rejects invalid user ID', () async {
      await expectLater(createTestMeal(userId: ''), throwsArgumentError);
    });

    test('rejects invalid weekly date range', () {
      expect(
        () => repository.watchMealsForRange(
          userId: userId,
          startDate: '2026-11-15',
          endDate: '2026-11-08',
        ),
        throwsArgumentError,
      );
    });
  });
}
