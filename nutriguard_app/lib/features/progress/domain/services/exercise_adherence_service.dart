import '../../../exercise/data/models/exercise_log_model.dart';

class ExerciseAdherenceResult {
  final int totalExercises;
  final int completedExercises;
  final int plannedExercises;
  final int completedMinutes;

  const ExerciseAdherenceResult({
    required this.totalExercises,
    required this.completedExercises,
    required this.plannedExercises,
    required this.completedMinutes,
  });

  double get completionPercentage {
    if (totalExercises == 0) {
      return 0;
    }

    return (completedExercises / totalExercises) * 100;
  }

  bool get hasData => totalExercises > 0;
}

class ExerciseAdherenceService {
  const ExerciseAdherenceService();

  ExerciseAdherenceResult calculate({
    required List<ExerciseLogModel> exerciseLogs,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day + 1);

    if (endExclusive.isBefore(start) || endExclusive.isAtSameMomentAs(start)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    final filtered = exerciseLogs.where((exercise) {
      final date = exercise.performedAt;

      return !date.isBefore(start) && date.isBefore(endExclusive);
    }).toList();

    final completed = filtered
        .where((exercise) => exercise.isCompleted)
        .toList();

    final planned = filtered
        .where((exercise) => !exercise.isCompleted)
        .toList();

    final completedMinutes = completed.fold<int>(
      0,
      (total, exercise) => total + exercise.durationMinutes,
    );

    return ExerciseAdherenceResult(
      totalExercises: filtered.length,
      completedExercises: completed.length,
      plannedExercises: planned.length,
      completedMinutes: completedMinutes,
    );
  }
}
