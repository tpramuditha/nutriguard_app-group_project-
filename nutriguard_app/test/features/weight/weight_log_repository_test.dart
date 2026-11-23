import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/weight/data/models/weight_log_model.dart';
import 'package:nutriguard_app/features/weight/data/repositories/weight_log_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late WeightLogRepository repository;

  WeightLogModel createWeight({
    String id = '',
    double kg = 65.5,
    DateTime? date,
  }) {
    return WeightLogModel(
      id: id,
      weightKg: kg,
      measuredAt: date ?? DateTime(2026, 11, 9, 8, 30),
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => user.uid).thenReturn('userA');
    when(() => auth.currentUser).thenReturn(user);

    repository = WeightLogRepository(firestore: firestore, auth: auth);
  });

  group('WeightLogRepository', () {
    test('adds a weight record under the signed-in user', () async {
      final id = await repository.addWeight(createWeight());

      expect(id, isNotEmpty);

      final document = await firestore
          .collection('users')
          .doc('userA')
          .collection('weightLogs')
          .doc(id)
          .get();

      expect(document.exists, true);
      expect(document.data()?['weightKg'], 65.5);
      expect(document.data()?['measuredAt'], isA<Timestamp>());
    });

    test('retrieves weight records newest first', () async {
      await repository.addWeight(
        createWeight(kg: 67.0, date: DateTime(2026, 10, 1)),
      );

      await repository.addWeight(
        createWeight(kg: 65.5, date: DateTime(2026, 11, 9)),
      );

      final result = await repository.getWeightLogs();

      expect(result.length, 2);
      expect(result.first.weightKg, 65.5);
      expect(result.last.weightKg, 67.0);
    });

    test('filters by inclusive calendar dates', () async {
      // Use historical dates to avoid future-date validation.
      await repository.addWeight(
        createWeight(kg: 70, date: DateTime(2026, 9, 30, 23, 59)),
      );

      await repository.addWeight(
        createWeight(kg: 69, date: DateTime(2026, 10, 1, 0, 0)),
      );

      await repository.addWeight(
        createWeight(kg: 68, date: DateTime(2026, 10, 9, 23, 59)),
      );

      await repository.addWeight(
        createWeight(kg: 67, date: DateTime(2026, 10, 10, 0, 0)),
      );

      final result = await repository.getWeightLogsForRange(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 9),
      );

      expect(result.length, 2);

      expect(result.map((weight) => weight.weightKg).toSet(), {69.0, 68.0});
    });

    test('returns empty list when no records exist', () async {
      final result = await repository.getWeightLogs();

      expect(result, isEmpty);
    });

    test('rejects an invalid date range', () async {
      await expectLater(
        repository.getWeightLogsForRange(
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });

    test('updates an existing weight record', () async {
      final id = await repository.addWeight(createWeight(kg: 65.5));

      await repository.updateWeight(createWeight(id: id, kg: 64.8));

      final result = await repository.getWeightLogs();

      expect(result.length, 1);
      expect(result.first.id, id);
      expect(result.first.weightKg, 64.8);
    });

    test('deletes an existing weight record', () async {
      final id = await repository.addWeight(createWeight());

      await repository.deleteWeight(id);

      final result = await repository.getWeightLogs();

      expect(result, isEmpty);
    });

    test('does not read another user weight records', () async {
      await repository.addWeight(createWeight());

      when(() => user.uid).thenReturn('userB');

      final result = await repository.getWeightLogs();

      expect(result, isEmpty);
    });

    test('rejects weight below 2 kg', () async {
      await expectLater(
        repository.addWeight(createWeight(kg: 1.5)),
        throwsArgumentError,
      );
    });

    test('rejects weight above 500 kg', () async {
      await expectLater(
        repository.addWeight(createWeight(kg: 501)),
        throwsArgumentError,
      );
    });

    test('rejects NaN weight', () async {
      await expectLater(
        repository.addWeight(createWeight(kg: double.nan)),
        throwsArgumentError,
      );
    });

    test('rejects infinite weight', () async {
      await expectLater(
        repository.addWeight(createWeight(kg: double.infinity)),
        throwsArgumentError,
      );
    });

    test('rejects future measurement date', () async {
      await expectLater(
        repository.addWeight(
          createWeight(date: DateTime.now().add(const Duration(days: 2))),
        ),
        throwsArgumentError,
      );
    });

    test('rejects update without document ID', () async {
      await expectLater(
        repository.updateWeight(createWeight(id: '')),
        throwsArgumentError,
      );
    });

    test('rejects delete without document ID', () async {
      await expectLater(repository.deleteWeight(''), throwsArgumentError);
    });

    test('rejects saving when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        repository.addWeight(createWeight()),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects reading when signed out', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(repository.getWeightLogs(), throwsA(isA<StateError>()));
    });
  });
}
