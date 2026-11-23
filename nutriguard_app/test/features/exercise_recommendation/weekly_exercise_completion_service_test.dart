import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/exercise_recommendation_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_schedule_service.dart';
import 'package:nutriguard_app/features/exercise_recommendation/domain/services/weekly_exercise_completion_service.dart';

void main() {
  const service = WeeklyExerciseCompletionService();
  const scheduleService = WeeklyExerciseScheduleService();

  const request = ExerciseRecommendationRequest(
    goal: FitnessGoal.generalFitness,
    activityLevel: ActivityLevel.beginner,
  );

  final weekStart = DateTime(2026, 11, 9);
  final schedule = scheduleService.generate(request: request);

  ExerciseLogModel makeLog({
    required int weekday,
    bool completed = true,
    String? name,
    String? type,
  }) {
    final planned = schedule.forWeekday(weekday).exercise!;

    return ExerciseLogModel(
      id: 'test-$weekday',
      exerciseName: name ?? planned.name,
      exerciseType: type ?? planned.type,
      durationMinutes: planned.durationMinutes,
      isCompleted: completed,
      performedAt: DateTime(2026, 11, 8 + weekday),
    );
  }

  group('Weekly Exercise Completion', () {
    test('recognizes a completed matching exercise', () {
      expect(
        service.isDayCompleted(
          schedule: schedule,
          weekStart: weekStart,
          weekday: 1,
          exerciseLogs: [makeLog(weekday: 1)],
        ),
        isTrue,
      );
    });

    test('planned exercise is not completed', () {
      expect(
        service.isDayCompleted(
          schedule: schedule,
          weekStart: weekStart,
          weekday: 1,
          exerciseLogs: [makeLog(weekday: 1, completed: false)],
        ),
        isFalse,
      );
    });

    test('different exercise does not count', () {
      expect(
        service.isDayCompleted(
          schedule: schedule,
          weekStart: weekStart,
          weekday: 1,
          exerciseLogs: [makeLog(weekday: 1, name: 'Different Exercise')],
        ),
        isFalse,
      );
    });

    test('exercise logged on another day does not count', () {
      expect(
        service.isDayCompleted(
          schedule: schedule,
          weekStart: weekStart,
          weekday: 1,
          exerciseLogs: [makeLog(weekday: 2)],
        ),
        isFalse,
      );
    });

    test('counts completed and remaining sessions', () {
      final logs = [makeLog(weekday: 1), makeLog(weekday: 2)];

      expect(
        service.completedSessions(
          schedule: schedule,
          weekStart: weekStart,
          exerciseLogs: logs,
        ),
        2,
      );

      expect(
        service.remainingSessions(
          schedule: schedule,
          weekStart: weekStart,
          exerciseLogs: logs,
        ),
        schedule.plannedSessions - 2,
      );
    });

    test('duplicate logs do not double-count sessions', () {
      final logs = [makeLog(weekday: 1), makeLog(weekday: 1)];

      expect(
        service.completedSessions(
          schedule: schedule,
          weekStart: weekStart,
          exerciseLogs: logs,
        ),
        1,
      );
    });

    test('Sunday remains a rest day', () {
      expect(
        service.isDayCompleted(
          schedule: schedule,
          weekStart: weekStart,
          weekday: 7,
          exerciseLogs: [],
        ),
        isFalse,
      );
    });
  });
}
