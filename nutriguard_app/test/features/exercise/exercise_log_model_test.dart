import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';

void main() {
  final performedAt = DateTime(2026, 11, 9, 8, 30);

  ExerciseLogModel createLog({
    String id = 'exercise-001',
    String exerciseName = 'Walking',
    String exerciseType = 'Cardio',
    int durationMinutes = 30,
    bool isCompleted = true,
    DateTime? date,
  }) {
    return ExerciseLogModel(
      id: id,
      exerciseName: exerciseName,
      exerciseType: exerciseType,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted,
      performedAt: date ?? performedAt,
    );
  }

  group('ExerciseLogModel', () {
    test('stores all exercise properties correctly', () {
      final log = createLog();

      expect(log.id, 'exercise-001');
      expect(log.exerciseName, 'Walking');
      expect(log.exerciseType, 'Cardio');
      expect(log.durationMinutes, 30);
      expect(log.isCompleted, true);
      expect(log.performedAt, performedAt);
    });

    test('converts exercise log to Firestore map', () {
      final log = createLog();

      final map = log.toMap();

      expect(map['exerciseName'], 'Walking');
      expect(map['exerciseType'], 'Cardio');
      expect(map['durationMinutes'], 30);
      expect(map['isCompleted'], true);
      expect(map['performedAt'], isA<Timestamp>());
      expect((map['performedAt'] as Timestamp).toDate(), performedAt);
    });

    test('creates model from Firestore map', () {
      final map = {
        'exerciseName': 'Cycling',
        'exerciseType': 'Cardio',
        'durationMinutes': 45,
        'isCompleted': false,
        'performedAt': Timestamp.fromDate(performedAt),
      };

      final log = ExerciseLogModel.fromMap(id: 'exercise-002', map: map);

      expect(log.id, 'exercise-002');
      expect(log.exerciseName, 'Cycling');
      expect(log.durationMinutes, 45);
      expect(log.isCompleted, false);
      expect(log.performedAt, performedAt);
    });

    test('preserves data during serialization round trip', () {
      final original = createLog();

      final restored = ExerciseLogModel.fromMap(
        id: original.id,
        map: original.toMap(),
      );

      expect(restored.id, original.id);
      expect(restored.exerciseName, original.exerciseName);
      expect(restored.exerciseType, original.exerciseType);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.performedAt, original.performedAt);
    });

    test('copyWith updates only selected fields', () {
      final original = createLog();

      final updated = original.copyWith(
        exerciseName: 'Running',
        durationMinutes: 20,
      );

      expect(updated.exerciseName, 'Running');
      expect(updated.durationMinutes, 20);

      expect(updated.id, original.id);
      expect(updated.exerciseType, original.exerciseType);
      expect(updated.isCompleted, original.isCompleted);
      expect(updated.performedAt, original.performedAt);
    });

    test('copyWith can change completion status', () {
      final original = createLog(isCompleted: false);

      final updated = original.copyWith(isCompleted: true);

      expect(original.isCompleted, false);
      expect(updated.isCompleted, true);
    });

    test('copyWith without arguments preserves values', () {
      final original = createLog();

      final updated = original.copyWith();

      expect(updated.id, original.id);
      expect(updated.exerciseName, original.exerciseName);
      expect(updated.exerciseType, original.exerciseType);
      expect(updated.durationMinutes, original.durationMinutes);
      expect(updated.isCompleted, original.isCompleted);
      expect(updated.performedAt, original.performedAt);
    });

    test('supports zero-duration planned exercise', () {
      final log = createLog(durationMinutes: 0, isCompleted: false);

      expect(log.durationMinutes, 0);
      expect(log.isCompleted, false);
    });
  });
}
