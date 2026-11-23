import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/exercise/data/models/exercise_log_model.dart';
import 'package:nutriguard_app/features/exercise/data/repositories/exercise_log_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late ExerciseLogRepository repository;

  final performedAt = DateTime(2026, 11, 9, 8, 30);

  ExerciseLogModel createExercise({
    String id = '',
    String name = 'Walking',
    String type = 'Cardio',
    int duration = 30,
    bool completed = true,
    DateTime? date,
  }) {
    return ExerciseLogModel(
      id: id,
      exerciseName: name,
      exerciseType: type,
      durationMinutes: duration,
      isCompleted: completed,
      performedAt: date ?? performedAt,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => user.uid).thenReturn('userA');
    when(() => auth.currentUser).thenReturn(user);

    repository = ExerciseLogRepository(firestore: firestore, auth: auth);
  });

  group('ExerciseLogRepository', () {
    test('adds exercise to signed-in user collection', () async {
      final id = await repository.addExercise(createExercise());

      expect(id, isNotEmpty);

      final document = await firestore
          .collection('users')
          .doc('userA')
          .collection('exerciseLogs')
          .doc(id)
          .get();

      expect(document.exists, true);
      expect(document.data()?['exerciseName'], 'Walking');
      expect(document.data()?['durationMinutes'], 30);
      expect(document.data()?['isCompleted'], true);
      expect(document.data()?['performedAt'], isA<Timestamp>());
    });

    test('returns exercise logs newest first', () async {
      await repository.addExercise(
        createExercise(name: 'Walking', date: DateTime(2026, 11, 7)),
      );

      await repository.addExercise(
        createExercise(name: 'Cycling', date: DateTime(2026, 11, 9)),
      );

      final result = await repository.getExerciseLogs();

      expect(result.length, 2);
      expect(result.first.exerciseName, 'Cycling');
      expect(result.last.exerciseName, 'Walking');
    });

    test('filters exercises by inclusive calendar dates', () async {
      await repository.addExercise(
        createExercise(name: 'Before', date: DateTime(2026, 10, 31, 23, 59)),
      );

      await repository.addExercise(
        createExercise(name: 'Start', date: DateTime(2026, 11, 1, 0, 0)),
      );

      await repository.addExercise(
        createExercise(name: 'End', date: DateTime(2026, 11, 9, 23, 59)),
      );

      await repository.addExercise(
        createExercise(name: 'After', date: DateTime(2026, 11, 10, 0, 0)),
      );

      final result = await repository.getExerciseLogsForRange(
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 9),
      );

      expect(result.length, 2);
      expect(result.map((e) => e.exerciseName).toSet(), {'Start', 'End'});
    });

    test('returns empty list when no exercises exist', () async {
      final result = await repository.getExerciseLogs();

      expect(result, isEmpty);
    });

    test('rejects invalid date range', () async {
      await expectLater(
        repository.getExerciseLogsForRange(
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });

    test('updates an existing exercise', () async {
      final id = await repository.addExercise(createExercise(completed: false));

      final updated = createExercise(id: id, completed: true, duration: 45);

      await repository.updateExercise(updated);

      final logs = await repository.getExerciseLogs();

      expect(logs.length, 1);
      expect(logs.first.id, id);
      expect(logs.first.isCompleted, true);
      expect(logs.first.durationMinutes, 45);
    });

    test('deletes an existing exercise', () async {
      final id = await repository.addExercise(createExercise());

      await repository.deleteExercise(id);

      final logs = await repository.getExerciseLogs();

      expect(logs, isEmpty);
    });

    test('does not read exercises belonging to another user', () async {
      await repository.addExercise(createExercise());

      when(() => user.uid).thenReturn('userB');

      final logs = await repository.getExerciseLogs();

      expect(logs, isEmpty);
    });

    test('rejects empty exercise name', () async {
      await expectLater(
        repository.addExercise(createExercise(name: '  ')),
        throwsArgumentError,
      );
    });

    test('rejects negative duration', () async {
      await expectLater(
        repository.addExercise(createExercise(duration: -5)),
        throwsArgumentError,
      );
    });

    test('rejects duration above 1440 minutes', () async {
      await expectLater(
        repository.addExercise(createExercise(duration: 1441)),
        throwsArgumentError,
      );
    });

    test('rejects empty exercise type', () async {
      await expectLater(
        repository.addExercise(createExercise(type: '')),
        throwsArgumentError,
      );
    });

    test('rejects update without document ID', () async {
      await expectLater(
        repository.updateExercise(createExercise(id: '')),
        throwsArgumentError,
      );
    });

    test('rejects delete without document ID', () async {
      await expectLater(repository.deleteExercise(''), throwsArgumentError);
    });

    test('does not allow adding exercise when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        repository.addExercise(createExercise()),
        throwsA(isA<StateError>()),
      );
    });

    test('does not allow reading exercises when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        repository.getExerciseLogs(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
