import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/repositories/food_log_repository.dart';

import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../../nutrition/data/repositories/nutrition_goal_repository.dart';

class ProgressDataSnapshot {
  final List<FoodLogModel> foodLogs;
  final NutritionGoalModel nutritionGoal;

  const ProgressDataSnapshot({
    required this.foodLogs,
    required this.nutritionGoal,
  });
}

class ProgressDataRepository {
  final FoodLogRepository _foodLogRepository;
  final NutritionGoalRepository _nutritionGoalRepository;

  ProgressDataRepository({
    FoodLogRepository? foodLogRepository,
    NutritionGoalRepository? nutritionGoalRepository,
  }) : _foodLogRepository = foodLogRepository ?? FoodLogRepository(),
       _nutritionGoalRepository =
           nutritionGoalRepository ?? NutritionGoalRepository();

  Future<ProgressDataSnapshot> loadProgressData({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }

    final results = await Future.wait<Object>([
      _foodLogRepository.getFoodLogs(userId: userId),
      _nutritionGoalRepository.getNutritionGoal(userId: userId),
    ]);

    return ProgressDataSnapshot(
      foodLogs: results[0] as List<FoodLogModel>,
      nutritionGoal: results[1] as NutritionGoalModel,
    );
  }
}
