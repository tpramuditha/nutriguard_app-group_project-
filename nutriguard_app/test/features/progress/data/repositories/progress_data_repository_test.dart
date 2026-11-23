import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';

import 'package:nutriguard_app/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:nutriguard_app/features/nutrition/data/repositories/nutrition_goal_repository.dart';

import 'package:nutriguard_app/features/progress/data/repositories/progress_data_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProgressDataRepository repository;

  const userId = 'progress_test_user';
  const otherUserId = 'progress_other_user';

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = ProgressDataRepository(
      foodLogRepository: FoodLogRepository(firestore: firestore),
      nutritionGoalRepository: NutritionGoalRepository(firestore: firestore),
    );
  });

  FoodLogModel createFoodLog({
    required DateTime loggedAt,
    double calories = 420,
    double protein = 15,
    double carbs = 58,
    double fat = 14,
  }) {
    return FoodLogModel(
      foodId: 'egg_fried_rice',
      foodName: 'Egg Fried Rice',
      source: 'manual',
      grams: 200,
      mealType: 'Lunch',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      loggedAt: loggedAt,
    );
  }

  Future<void> saveTestLog({
    String targetUserId = userId,
    required String documentId,
    required FoodLogModel log,
  }) async {
    await firestore
        .collection('users')
        .doc(targetUserId)
        .collection('foodLogs')
        .doc(documentId)
        .set(log.toMap());
  }

  Future<void> saveTestGoal({
    String targetUserId = userId,
    required int calories,
    String goalType = 'Maintain Weight',
  }) async {
    final nutritionGoal = NutritionGoalModel(
      dailyCalorieTarget: calories,
      goalType: goalType,
    );

    await firestore
        .collection('users')
        .doc(targetUserId)
        .collection('preferences')
        .doc('nutrition')
        .set(nutritionGoal.toMap());
  }

  group('ProgressDataRepository', () {
    test('loads existing food logs', () async {
      await saveTestLog(
        documentId: 'log_001',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8, 12), calories: 420),
      );

      final snapshot = await repository.loadProgressData(userId: userId);

      expect(snapshot.foodLogs.length, 1);
      expect(snapshot.foodLogs.first.foodName, 'Egg Fried Rice');
      expect(snapshot.foodLogs.first.calories, 420);
    });

    test('loads saved nutrition goal', () async {
      await saveTestGoal(calories: 1800, goalType: 'Weight Loss');

      final snapshot = await repository.loadProgressData(userId: userId);

      expect(snapshot.nutritionGoal.dailyCalorieTarget, 1800);
      expect(snapshot.nutritionGoal.goalType, 'Weight Loss');
    });

    test('returns default goal when no goal is saved', () async {
      final snapshot = await repository.loadProgressData(userId: userId);

      expect(
        snapshot.nutritionGoal.dailyCalorieTarget,
        NutritionGoalModel.defaultGoal.dailyCalorieTarget,
      );

      expect(
        snapshot.nutritionGoal.goalType,
        NutritionGoalModel.defaultGoal.goalType,
      );
    });

    test('returns empty logs for a new user', () async {
      final snapshot = await repository.loadProgressData(userId: userId);

      expect(snapshot.foodLogs, isEmpty);
    });

    test('loads multiple food logs in descending date order', () async {
      await saveTestLog(
        documentId: 'log_old',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 6), calories: 260),
      );

      await saveTestLog(
        documentId: 'log_new',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 420),
      );

      final snapshot = await repository.loadProgressData(userId: userId);

      expect(snapshot.foodLogs.length, 2);
      expect(snapshot.foodLogs[0].calories, 420);
      expect(snapshot.foodLogs[1].calories, 260);
    });

    test('loads only data belonging to requested user', () async {
      await saveTestLog(
        documentId: 'owner_log',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 420),
      );

      await saveTestLog(
        targetUserId: otherUserId,
        documentId: 'other_log',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8), calories: 900),
      );

      await saveTestGoal(calories: 1800);

      await saveTestGoal(targetUserId: otherUserId, calories: 2500);

      final snapshot = await repository.loadProgressData(userId: userId);

      expect(snapshot.foodLogs.length, 1);
      expect(snapshot.foodLogs.first.calories, 420);
      expect(snapshot.nutritionGoal.dailyCalorieTarget, 1800);
    });

    test('rejects empty user ID', () async {
      await expectLater(
        repository.loadProgressData(userId: ''),
        throwsArgumentError,
      );
    });

    test('loads food logs and nutrition goal together', () async {
      await saveTestLog(
        documentId: 'log_001',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8, 8), calories: 260),
      );

      await saveTestLog(
        documentId: 'log_002',
        log: createFoodLog(loggedAt: DateTime(2026, 11, 8, 13), calories: 420),
      );

      await saveTestGoal(calories: 2200, goalType: 'Weight Gain');

      final snapshot = await repository.loadProgressData(userId: userId);

      final totalCalories = snapshot.foodLogs.fold<double>(
        0,
        (sum, log) => sum + log.calories,
      );

      expect(snapshot.foodLogs.length, 2);
      expect(totalCalories, 680);
      expect(snapshot.nutritionGoal.dailyCalorieTarget, 2200);
      expect(snapshot.nutritionGoal.goalType, 'Weight Gain');
    });
  });
}
