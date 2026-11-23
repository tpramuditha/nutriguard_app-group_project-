import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:nutriguard_app/features/nutrition/data/repositories/nutrition_goal_repository.dart';

void main() {
  const userId = 'test-user';

  late FakeFirebaseFirestore firestore;
  late NutritionGoalRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = NutritionGoalRepository(firestore: firestore);
  });

  test('returns default goal when no document exists', () async {
    final goal = await repository.getNutritionGoal(userId: userId);

    expect(goal.dailyCalorieTarget, 2000);
    expect(goal.goalType, 'Maintain Weight');
  });

  test('saves and retrieves a nutrition goal', () async {
    const goal = NutritionGoalModel(
      dailyCalorieTarget: 1800,
      goalType: 'Weight Loss',
    );

    await repository.saveNutritionGoal(userId: userId, goal: goal);

    final saved = await repository.getNutritionGoal(userId: userId);

    expect(saved.dailyCalorieTarget, 1800);
    expect(saved.goalType, 'Weight Loss');
  });

  test('updates an existing nutrition goal', () async {
    await repository.saveNutritionGoal(
      userId: userId,
      goal: const NutritionGoalModel(
        dailyCalorieTarget: 1800,
        goalType: 'Weight Loss',
      ),
    );

    await repository.saveNutritionGoal(
      userId: userId,
      goal: const NutritionGoalModel(
        dailyCalorieTarget: 2300,
        goalType: 'Weight Gain',
      ),
    );

    final updated = await repository.getNutritionGoal(userId: userId);

    expect(updated.dailyCalorieTarget, 2300);
    expect(updated.goalType, 'Weight Gain');
  });

  test('different users have separate nutrition goals', () async {
    await repository.saveNutritionGoal(
      userId: 'user-one',
      goal: const NutritionGoalModel(
        dailyCalorieTarget: 1700,
        goalType: 'Weight Loss',
      ),
    );

    await repository.saveNutritionGoal(
      userId: 'user-two',
      goal: const NutritionGoalModel(
        dailyCalorieTarget: 2500,
        goalType: 'Weight Gain',
      ),
    );

    final first = await repository.getNutritionGoal(userId: 'user-one');

    final second = await repository.getNutritionGoal(userId: 'user-two');

    expect(first.dailyCalorieTarget, 1700);
    expect(second.dailyCalorieTarget, 2500);
  });

  test('rejects zero or negative calorie targets', () async {
    for (final calories in [0, -100]) {
      await expectLater(
        repository.saveNutritionGoal(
          userId: userId,
          goal: NutritionGoalModel(
            dailyCalorieTarget: calories,
            goalType: 'Maintain Weight',
          ),
        ),
        throwsArgumentError,
      );
    }
  });

  test('rejects calorie targets above 10000', () async {
    await expectLater(
      repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 10001,
          goalType: 'Maintain Weight',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid goal types', () async {
    await expectLater(
      repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 2000,
          goalType: 'Invalid Goal',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects an empty user ID', () async {
    await expectLater(
      repository.getNutritionGoal(userId: ''),
      throwsArgumentError,
    );
  });

  test('uses default values for malformed stored data', () async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('nutrition')
        .set({'dailyCalorieTarget': -500, 'goalType': 'Unknown'});

    final goal = await repository.getNutritionGoal(userId: userId);

    expect(goal.dailyCalorieTarget, 2000);
    expect(goal.goalType, 'Maintain Weight');
  });
}
