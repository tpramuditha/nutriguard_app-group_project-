import '../../data/models/exercise_recommendation_model.dart';

class ExerciseSessionArguments {
  final ExerciseRecommendationModel recommendation;
  final DateTime plannedDate;

  const ExerciseSessionArguments({
    required this.recommendation,
    required this.plannedDate,
  });
}
