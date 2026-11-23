import '../models/food_log_model.dart';
import '../models/food_model.dart';

class FoodRelogMapper {
  static FoodModel fromFoodLog(FoodLogModel log) {
    if (!log.grams.isFinite || log.grams <= 0 || log.grams > 5000) {
      throw ArgumentError('Invalid portion size in saved food log.');
    }

    final values = [log.calories, log.protein, log.carbs, log.fat];

    if (values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Invalid nutrition values in saved food log.');
    }

    final factor = 100 / log.grams;

    return FoodModel(
      id: log.foodId,
      name: log.foodName,
      brand: log.brand,
      source: log.source,
      caloriesPer100g: log.calories * factor,
      proteinPer100g: log.protein * factor,
      carbsPer100g: log.carbs * factor,
      fatPer100g: log.fat * factor,
    );
  }
}
