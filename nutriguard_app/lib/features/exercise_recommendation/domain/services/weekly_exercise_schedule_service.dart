import '../../data/models/exercise_recommendation_model.dart';
import 'exercise_recommendation_service.dart';

class DailyExercisePlan {
  // 1 = Monday, 7 = Sunday.
  final int weekday;
  final ExerciseRecommendationModel? exercise;

  const DailyExercisePlan({required this.weekday, required this.exercise});

  bool get isRestDay => exercise == null;

  String get dayName {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (weekday < 1 || weekday > 7) {
      throw StateError('Invalid weekday.');
    }

    return names[weekday - 1];
  }
}

class WeeklyExerciseSchedule {
  final List<DailyExercisePlan> days;

  const WeeklyExerciseSchedule({required this.days});

  DailyExercisePlan forWeekday(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7.');
    }

    return days.firstWhere((day) => day.weekday == weekday);
  }

  int get plannedSessions {
    return days.where((day) => !day.isRestDay).length;
  }

  int get plannedMinutes {
    return days.fold<int>(
      0,
      (total, day) => total + (day.exercise?.durationMinutes ?? 0),
    );
  }
}

class WeeklyExerciseScheduleService {
  final ExerciseRecommendationService _recommendationService;

  const WeeklyExerciseScheduleService({
    this._recommendationService = const ExerciseRecommendationService(),
  });

  WeeklyExerciseSchedule generate({
    required ExerciseRecommendationRequest request,
  }) {
    // Get the full eligible catalog in recommendation
    // ranking order to provide a variety of activities.
    final exercises = _recommendationService.recommend(
      request: request,
      maxResults: 100,
    );

    final days = <DailyExercisePlan>[];

    for (var weekday = 1; weekday <= 7; weekday++) {
      // Sunday is a recovery/rest day in this
      // introductory sample schedule.
      if (weekday == DateTime.sunday || exercises.isEmpty) {
        days.add(DailyExercisePlan(weekday: weekday, exercise: null));

        continue;
      }

      // Rotate through eligible exercises.
      final exerciseIndex = (weekday - 1) % exercises.length;

      days.add(
        DailyExercisePlan(weekday: weekday, exercise: exercises[exerciseIndex]),
      );
    }

    return WeeklyExerciseSchedule(days: List.unmodifiable(days));
  }
}
