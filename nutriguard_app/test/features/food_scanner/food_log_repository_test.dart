import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/food_scanner/data/models/food_log_model.dart';
import 'package:nutriguard_app/features/food_scanner/data/repositories/food_log_repository.dart';

void main() {
  const userId = 'test-user';

  late FakeFirebaseFirestore firestore;
  late FoodLogRepository repository;

  FoodLogModel makeFoodLog({
    String name = 'Rice and Dhal Curry',
    double calories = 150,
  }) {
    return FoodLogModel(
      foodId: 'manual-test-food',
      foodName: name,
      brand: null,
      source: 'Manual Entry',
      grams: 100,
      mealType: 'Breakfast',
      calories: calories,
      protein: 10,
      carbs: 20,
      fat: 5,
      loggedAt: DateTime(2026, 11, 2, 9),
    );
  }

  Future<int> countFoodLogs() async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('foodLogs')
        .get();

    return snapshot.docs.length;
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FoodLogRepository(firestore: firestore);
  });

  test('first submission creates one food log', () async {
    final id = await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    expect(id, 'submission-001');
    expect(await countFoodLogs(), 1);

    final logs = await repository.getFoodLogs(userId: userId);

    expect(logs.length, 1);
    expect(logs.first.foodName, 'Rice and Dhal Curry');
  });

  test('retry with same ID and same data creates no duplicate', () async {
    final firstId = await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    final secondId = await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    expect(firstId, secondId);
    expect(await countFoodLogs(), 1);
  });

  test('same ID with different food details is rejected', () async {
    await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    await expectLater(
      repository.saveFoodLog(
        userId: userId,
        foodLog: makeFoodLog(name: 'Chicken Kottu'),
        submissionId: 'submission-001',
      ),
      throwsStateError,
    );

    expect(await countFoodLogs(), 1);

    final logs = await repository.getFoodLogs(userId: userId);

    expect(logs.single.foodName, 'Rice and Dhal Curry');
  });

  test('same ID with changed calories is rejected', () async {
    await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    await expectLater(
      repository.saveFoodLog(
        userId: userId,
        foodLog: makeFoodLog(calories: 300),
        submissionId: 'submission-001',
      ),
      throwsStateError,
    );

    expect(await countFoodLogs(), 1);
  });

  test('different submission IDs create separate food logs', () async {
    await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-001',
    );

    await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
      submissionId: 'submission-002',
    );

    expect(await countFoodLogs(), 2);
  });

  test('saving without submission ID preserves normal behavior', () async {
    final firstId = await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
    );

    final secondId = await repository.saveFoodLog(
      userId: userId,
      foodLog: makeFoodLog(),
    );

    expect(firstId, isNot(secondId));
    expect(await countFoodLogs(), 2);
  });

  test('invalid submission ID is rejected', () async {
    await expectLater(
      repository.saveFoodLog(
        userId: userId,
        foodLog: makeFoodLog(),
        submissionId: 'invalid/id',
      ),
      throwsArgumentError,
    );

    expect(await countFoodLogs(), 0);
  });

  test('empty user ID is rejected', () async {
    await expectLater(
      repository.saveFoodLog(
        userId: '',
        foodLog: makeFoodLog(),
        submissionId: 'submission-001',
      ),
      throwsArgumentError,
    );
  });

  test('same submission ID with different foodId is rejected', () async {
    final originalLog = makeFoodLog();

    await repository.saveFoodLog(
      userId: userId,
      foodLog: originalLog,
      submissionId: 'submission-001',
    );

    final changedLog = FoodLogModel(
      foodId: 'different-food-id',
      foodName: originalLog.foodName,
      brand: originalLog.brand,
      source: originalLog.source,
      grams: originalLog.grams,
      mealType: originalLog.mealType,
      calories: originalLog.calories,
      protein: originalLog.protein,
      carbs: originalLog.carbs,
      fat: originalLog.fat,
      loggedAt: originalLog.loggedAt,
    );

    await expectLater(
      repository.saveFoodLog(
        userId: userId,
        foodLog: changedLog,
        submissionId: 'submission-001',
      ),
      throwsStateError,
    );

    expect(await countFoodLogs(), 1);
  });

  test('same submission ID with different loggedAt is rejected', () async {
    final originalLog = makeFoodLog();

    await repository.saveFoodLog(
      userId: userId,
      foodLog: originalLog,
      submissionId: 'submission-001',
    );

    final changedLog = FoodLogModel(
      foodId: originalLog.foodId,
      foodName: originalLog.foodName,
      brand: originalLog.brand,
      source: originalLog.source,
      grams: originalLog.grams,
      mealType: originalLog.mealType,
      calories: originalLog.calories,
      protein: originalLog.protein,
      carbs: originalLog.carbs,
      fat: originalLog.fat,
      loggedAt: originalLog.loggedAt.add(const Duration(minutes: 1)),
    );

    await expectLater(
      repository.saveFoodLog(
        userId: userId,
        foodLog: changedLog,
        submissionId: 'submission-001',
      ),
      throwsStateError,
    );

    expect(await countFoodLogs(), 1);
  });
}
