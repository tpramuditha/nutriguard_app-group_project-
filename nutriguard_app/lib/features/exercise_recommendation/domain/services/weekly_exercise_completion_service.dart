import '../../../exercise/data/models/exercise_log_model.dart';
import 'weekly_exercise_schedule_service.dart';

class WeeklyExerciseCompletionService {
  const WeeklyExerciseCompletionService();

  bool isDayCompleted({
    required WeeklyExerciseSchedule schedule,
    required DateTime weekStart,
    required int weekday,
    required List<ExerciseLogModel> exerciseLogs,
  }) {
    final day = schedule.forWeekday(weekday);

    if (day.isRestDay) {
      return false;
    }

    final plannedExercise = day.exercise!;

    final plannedDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + weekday - 1,
    );

    return exerciseLogs.any((log) {
      if (!log.isCompleted) {
        return false;
      }

      final logDate = DateTime(
        log.performedAt.year,
        log.performedAt.month,
        log.performedAt.day,
      );

      return logDate == plannedDate &&
          log.exerciseName == plannedExercise.name &&
          log.exerciseType == plannedExercise.type;
    });
  }

  int completedSessions({
    required WeeklyExerciseSchedule schedule,
    required DateTime weekStart,
    required List<ExerciseLogModel> exerciseLogs,
  }) {
    var completed = 0;

    for (var weekday = 1; weekday <= 7; weekday++) {
      if (isDayCompleted(
        schedule: schedule,
        weekStart: weekStart,
        weekday: weekday,
        exerciseLogs: exerciseLogs,
      )) {
        completed++;
      }
    }

    return completed;
  }

  int remainingSessions({
    required WeeklyExerciseSchedule schedule,
    required DateTime weekStart,
    required List<ExerciseLogModel> exerciseLogs,
  }) {
    final completed = completedSessions(
      schedule: schedule,
      weekStart: weekStart,
      exerciseLogs: exerciseLogs,
    );

    return schedule.plannedSessions - completed;
  }
}
