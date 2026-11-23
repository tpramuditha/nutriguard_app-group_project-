import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/nutrition/data/models/nutrition_goal_model.dart';
import 'package:nutriguard_app/features/nutrition/data/repositories/nutrition_goal_repository.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_goal_ranking_service.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_nutrition_goal_loader.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NutritionGoalRepository repository;
  late RecipeNutritionGoalLoader loader;

  const rankingService = RecipeGoalRankingService();

  const userId = 'test_user_001';

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = NutritionGoalRepository(firestore: firestore);

    loader = RecipeNutritionGoalLoader(repository: repository);
  });

  group('RecipeNutritionGoalLoader', () {
    test('returns default goal when no goal is saved', () async {
      final goal = await loader.loadGoal(userId: userId);

      expect(goal.dailyCalorieTarget, 2000);
      expect(goal.goalType, 'Maintain Weight');
    });

    test('loads saved nutrition goal from Firestore', () async {
      await repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 2400,
          goalType: 'Weight Gain',
        ),
      );

      final goal = await loader.loadGoal(userId: userId);

      expect(goal.dailyCalorieTarget, 2400);
      expect(goal.goalType, 'Weight Gain');
    });

    test('loads updated nutrition goal', () async {
      await repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 2000,
          goalType: 'Maintain Weight',
        ),
      );

      await repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 1800,
          goalType: 'Weight Loss',
        ),
      );

      final goal = await loader.loadGoal(userId: userId);

      expect(goal.dailyCalorieTarget, 1800);
      expect(goal.goalType, 'Weight Loss');
    });

    test('rejects empty user ID', () async {
      await expectLater(loader.loadGoal(userId: ''), throwsArgumentError);
    });

    test('rejects whitespace-only user ID', () async {
      await expectLater(loader.loadGoal(userId: '   '), throwsArgumentError);
    });

    test('returns separate nutrition goals for users', () async {
      await repository.saveNutritionGoal(
        userId: 'user_a',
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 1800,
          goalType: 'Weight Loss',
        ),
      );

      await repository.saveNutritionGoal(
        userId: 'user_b',
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 2600,
          goalType: 'Weight Gain',
        ),
      );

      final goalA = await loader.loadGoal(userId: 'user_a');

      final goalB = await loader.loadGoal(userId: 'user_b');

      expect(goalA.dailyCalorieTarget, 1800);
      expect(goalB.dailyCalorieTarget, 2600);
      expect(goalA.goalType, 'Weight Loss');
      expect(goalB.goalType, 'Weight Gain');
    });

    test('loaded goal works with recipe ranking service', () async {
      await repository.saveNutritionGoal(
        userId: userId,
        goal: const NutritionGoalModel(
          dailyCalorieTarget: 2100,
          goalType: 'Maintain Weight',
        ),
      );

      final goal = await loader.loadGoal(userId: userId);

      final guide = rankingService.estimatedMealCalorieGuide(goal);

      expect(guide, closeTo(700, 0.001));
    });

    test('default goal produces estimated meal guide', () async {
      final goal = await loader.loadGoal(userId: userId);

      final guide = rankingService.estimatedMealCalorieGuide(goal);

      expect(guide, closeTo(666.6667, 0.01));
    });
  });
}
