import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../../nutrition/data/repositories/nutrition_goal_repository.dart';

class RecipeNutritionGoalLoader {
  final NutritionGoalRepository _repository;

  RecipeNutritionGoalLoader({NutritionGoalRepository? repository})
    : _repository = repository ?? NutritionGoalRepository();

  Future<NutritionGoalModel> loadGoal({required String userId}) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A valid user ID is required.');
    }

    return _repository.getNutritionGoal(userId: userId);
  }
}
