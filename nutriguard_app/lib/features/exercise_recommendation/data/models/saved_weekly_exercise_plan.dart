import '../../domain/services/exercise_plan_date_service.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import '../../domain/services/weekly_exercise_schedule_service.dart';

class SavedWeeklyExercisePlan {
  final DateTime weekStart;
  final ExerciseRecommendationRequest request;
  final WeeklyExerciseSchedule schedule;

  const SavedWeeklyExercisePlan({
    required this.weekStart,
    required this.request,
    required this.schedule,
  });

  factory SavedWeeklyExercisePlan.fromSchedule({
    required DateTime referenceDate,
    required ExerciseRecommendationRequest request,
    required WeeklyExerciseSchedule schedule,
  }) {
    const dateService = ExercisePlanDateService();

    final monday = dateService.dateForWeekday(
      referenceDate: referenceDate,
      weekday: DateTime.monday,
    );

    return SavedWeeklyExercisePlan(
      weekStart: monday,
      request: request,
      schedule: schedule,
    );
  }

  String get weekId {
    final year = weekStart.year;
    final month = weekStart.month.toString().padLeft(2, '0');
    final day = weekStart.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekId,
      'goal': request.goal.name,
      'activityLevel': request.activityLevel.name,
      'preference': request.preference.name,
      'days': schedule.days.map((day) {
        return {'weekday': day.weekday, 'exerciseId': day.exercise?.id};
      }).toList(),
    };
  }

  factory SavedWeeklyExercisePlan.fromMap(Map<String, dynamic> map) {
    final request = ExerciseRecommendationRequest(
      goal: FitnessGoal.values.byName(map['goal'] as String),
      activityLevel: ActivityLevel.values.byName(
        map['activityLevel'] as String,
      ),
      preference: ExercisePreference.values.byName(map['preference'] as String),
    );

    // Get eligible exercise details from the
    // application's existing exercise catalog.
    const service = ExerciseRecommendationService();

    final availableExercises = service.recommend(
      request: request,
      maxResults: 100,
    );

    final rawDays = map['days'] as List<dynamic>;

    if (rawDays.length != 7) {
      throw const FormatException(
        'A weekly exercise plan must have seven days.',
      );
    }

    final days = <DailyExercisePlan>[];

    for (var index = 0; index < 7; index++) {
      final data = Map<String, dynamic>.from(rawDays[index] as Map);

      final weekday = data['weekday'] as int;
      final exerciseId = data['exerciseId'] as String?;

      if (weekday != index + 1) {
        throw const FormatException('Invalid weekday sequence.');
      }

      if (weekday == DateTime.sunday) {
        if (exerciseId != null) {
          throw const FormatException('Sunday must be a rest day.');
        }

        days.add(DailyExercisePlan(weekday: weekday, exercise: null));
        continue;
      }

      if (exerciseId == null) {
        throw const FormatException('Missing exercise for a planned day.');
      }

      final matches = availableExercises.where(
        (exercise) => exercise.id == exerciseId,
      );

      if (matches.isEmpty) {
        throw FormatException('Unknown or ineligible exercise: $exerciseId');
      }

      days.add(DailyExercisePlan(weekday: weekday, exercise: matches.first));
    }

    return SavedWeeklyExercisePlan(
      weekStart: DateTime.parse(map['weekStart'] as String),
      request: request,
      schedule: WeeklyExerciseSchedule(days: List.unmodifiable(days)),
    );
  }
}
