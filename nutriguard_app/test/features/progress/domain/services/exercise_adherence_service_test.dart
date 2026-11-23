import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';
import 'package:nutriguard_app/features/progress/domain/services/exercise_adherence_service.dart';

void main() {
  const service = ExerciseAdherenceService();

  ExerciseLogModel createExercise({
    required String id,
    required DateTime date,
    bool completed = true,
    int duration = 30,
  }) {
    return ExerciseLogModel(
      id: id,
      exerciseName: 'Walking',
      exerciseType: 'Cardio',
      durationMinutes: duration,
      isCompleted: completed,
      performedAt: date,
    );
  }

  group('ExerciseAdherenceService', () {
    test('returns zero values when no exercises exist', () {
      final result = service.calculate(
        exerciseLogs: [],
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 0);
      expect(result.completedExercises, 0);
      expect(result.plannedExercises, 0);
      expect(result.completedMinutes, 0);
      expect(result.completionPercentage, 0);
      expect(result.hasData, false);
    });

    test('calculates completion percentage correctly', () {
      final logs = [
        createExercise(id: '1', date: DateTime(2026, 11, 1), completed: true),
        createExercise(id: '2', date: DateTime(2026, 11, 2), completed: true),
        createExercise(id: '3', date: DateTime(2026, 11, 3), completed: true),
        createExercise(id: '4', date: DateTime(2026, 11, 4), completed: false),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 4);
      expect(result.completedExercises, 3);
      expect(result.plannedExercises, 1);
      expect(result.completionPercentage, 75);
      expect(result.hasData, true);
    });

    test('calculates completed exercise minutes only', () {
      final logs = [
        createExercise(
          id: '1',
          date: DateTime(2026, 11, 1),
          completed: true,
          duration: 30,
        ),
        createExercise(
          id: '2',
          date: DateTime(2026, 11, 2),
          completed: true,
          duration: 45,
        ),
        createExercise(
          id: '3',
          date: DateTime(2026, 11, 3),
          completed: false,
          duration: 60,
        ),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.completedMinutes, 75);
      expect(result.plannedExercises, 1);
    });

    test('returns 100 percent when all are completed', () {
      final logs = [
        createExercise(id: '1', date: DateTime(2026, 11, 1)),
        createExercise(id: '2', date: DateTime(2026, 11, 2)),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.completionPercentage, 100);
      expect(result.completedExercises, 2);
      expect(result.plannedExercises, 0);
    });

    test('returns zero percent when none are completed', () {
      final logs = [
        createExercise(id: '1', date: DateTime(2026, 11, 1), completed: false),
        createExercise(id: '2', date: DateTime(2026, 11, 2), completed: false),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.completionPercentage, 0);
      expect(result.completedMinutes, 0);
      expect(result.plannedExercises, 2);
      expect(result.hasData, true);
    });

    test('excludes exercises outside selected period', () {
      final logs = [
        createExercise(id: 'before', date: DateTime(2026, 10, 31)),
        createExercise(id: 'inside', date: DateTime(2026, 11, 5)),
        createExercise(id: 'after', date: DateTime(2026, 11, 10)),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 1);
      expect(result.completedExercises, 1);
      expect(result.completedMinutes, 30);
    });

    test('includes both start and end calendar days', () {
      final logs = [
        createExercise(id: 'start', date: DateTime(2026, 11, 1, 0, 0)),
        createExercise(id: 'end', date: DateTime(2026, 11, 9, 23, 59)),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 2);
      expect(result.completedExercises, 2);
      expect(result.completedMinutes, 60);
    });

    test('supports a single-day date range', () {
      final logs = [
        createExercise(id: 'today', date: DateTime(2026, 11, 9, 10, 30)),
        createExercise(id: 'yesterday', date: DateTime(2026, 11, 8)),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 1);
      expect(result.completionPercentage, 100);
    });

    test('rejects an invalid date range', () {
      expect(
        () => service.calculate(
          exerciseLogs: [],
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });

    test('does not count planned minutes as completed', () {
      final logs = [
        createExercise(
          id: 'planned',
          date: DateTime(2026, 11, 9),
          completed: false,
          duration: 120,
        ),
      ];

      final result = service.calculate(
        exerciseLogs: logs,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.totalExercises, 1);
      expect(result.plannedExercises, 1);
      expect(result.completedExercises, 0);
      expect(result.completedMinutes, 0);
    });
  });
}
