import '../../data/models/exercise_recommendation_model.dart';
import 'exercise_recommendation_service.dart';
import 'weekly_exercise_schedule_service.dart';

class ExerciseSwapService {
  final ExerciseRecommendationService _recommendationService;

  const ExerciseSwapService({
    this._recommendationService = const ExerciseRecommendationService(),
  });

  List<ExerciseRecommendationModel> getAlternatives({
    required WeeklyExerciseSchedule schedule,
    required int weekday,
    required ExerciseRecommendationRequest request,
  }) {
    final day = schedule.forWeekday(weekday);

    if (day.isRestDay) {
      return [];
    }

    final currentExercise = day.exercise!;

    final eligible = _recommendationService.recommend(
      request: request,
      maxResults: 100,
    );

    // Do not include the currently selected exercise.
    return eligible
        .where((exercise) => exercise.id != currentExercise.id)
        .toList();
  }

  WeeklyExerciseSchedule swapExercise({
    required WeeklyExerciseSchedule schedule,
    required int weekday,
    required ExerciseRecommendationRequest request,
    required String replacementExerciseId,
  }) {
    final day = schedule.forWeekday(weekday);

    if (day.isRestDay) {
      throw StateError('Cannot replace an exercise on a rest day.');
    }

    final alternatives = getAlternatives(
      schedule: schedule,
      weekday: weekday,
      request: request,
    );

    ExerciseRecommendationModel? replacement;

    for (final exercise in alternatives) {
      if (exercise.id == replacementExerciseId) {
        replacement = exercise;
        break;
      }
    }

    if (replacement == null) {
      throw ArgumentError('Replacement exercise is not eligible.');
    }

    final updatedDays = schedule.days.map((existingDay) {
      if (existingDay.weekday == weekday) {
        return DailyExercisePlan(weekday: weekday, exercise: replacement);
      }

      return existingDay;
    }).toList();

    // Return a new schedule instead of modifying the
    // original schedule.
    return WeeklyExerciseSchedule(days: List.unmodifiable(updatedDays));
  }
}
