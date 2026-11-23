import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';
import 'package:nutriguard_app/features/health/data/repositories/monthly_health_marker_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late MonthlyHealthMarkerRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();

    when(() => user.uid).thenReturn('userA');
    when(() => auth.currentUser).thenReturn(user);

    repository = MonthlyHealthMarkerRepository(
      firestore: firestore,
      auth: auth,
    );
  });

  test('saves monthly markers under the correct user and month', () async {
    const markers = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(markers);

    final document = await firestore
        .collection('users')
        .doc('userA')
        .collection('monthlyHealthMarkers')
        .doc('2026-10')
        .get();

    expect(document.exists, true);
    expect(document.data()?['month'], '2026-10');

    final savedMeasurements = document.data()?['measurements'] as List;

    expect(savedMeasurements.length, 1);
    expect(savedMeasurements.first['value'], 185);
  });

  test('retrieves saved monthly markers', () async {
    const markers = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Fasting Blood Glucose',
          value: 95,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(markers);

    final result = await repository.getMarkers('2026-10');

    expect(result, isNotNull);
    expect(result!.month, '2026-10');
    expect(result.measurements.length, 1);
    expect(result.measurements.first.name, 'Fasting Blood Glucose');
    expect(result.measurements.first.value, 95);
  });

  test('returns null when the selected month has no markers', () async {
    final result = await repository.getMarkers('2026-09');

    expect(result, isNull);
  });

  test('does not mix markers belonging to different users', () async {
    const markers = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'HDL Cholesterol',
          value: 55,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(markers);

    when(() => user.uid).thenReturn('userB');

    final result = await repository.getMarkers('2026-10');

    expect(result, isNull);
  });

  test('does not allow saving when signed out', () async {
    when(() => auth.currentUser).thenReturn(null);

    const markers = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
      ],
    );

    await expectLater(
      repository.saveMarkers(markers),
      throwsA(isA<StateError>()),
    );
  });

  test('does not allow reading when signed out', () async {
    when(() => auth.currentUser).thenReturn(null);

    await expectLater(
      repository.getMarkers('2026-10'),
      throwsA(isA<StateError>()),
    );
  });

  test('adding glucose preserves existing cholesterol', () async {
    const cholesterol = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
      ],
    );

    const glucose = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Fasting Blood Glucose',
          value: 95,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(cholesterol);
    await repository.saveMarkers(glucose);

    final result = await repository.getMarkers('2026-10');

    expect(result, isNotNull);
    expect(result!.measurements.length, 2);

    expect(
      result.measurements.any(
        (m) => m.name == 'Total Cholesterol' && m.value == 185,
      ),
      true,
    );

    expect(
      result.measurements.any(
        (m) => m.name == 'Fasting Blood Glucose' && m.value == 95,
      ),
      true,
    );
  });

  test('saving an existing marker updates its value', () async {
    const original = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
      ],
    );

    const updated = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 190,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(original);
    await repository.saveMarkers(updated);

    final result = await repository.getMarkers('2026-10');

    expect(result, isNotNull);
    expect(result!.measurements.length, 1);
    expect(result.measurements.first.value, 190);
  });

  test('different months keep separate measurements', () async {
    const october = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
      ],
    );

    const september = MonthlyHealthMarkerModel(
      month: '2026-09',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 175,
          unit: 'mg/dL',
        ),
      ],
    );

    await repository.saveMarkers(october);
    await repository.saveMarkers(september);

    final octoberResult = await repository.getMarkers('2026-10');

    final septemberResult = await repository.getMarkers('2026-09');

    expect(octoberResult!.measurements.first.value, 185);
    expect(septemberResult!.measurements.first.value, 175);
  });

  test('duplicate measurement names are rejected', () async {
    const markers = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 190,
          unit: 'mg/dL',
        ),
      ],
    );

    await expectLater(
      repository.saveMarkers(markers),
      throwsA(isA<ArgumentError>()),
    );
  });

  group('Historical Health Marker Range Tests', () {
    Future<void> saveTestMonth({
      required String month,
      required double cholesterol,
    }) async {
      await repository.saveMarkers(
        MonthlyHealthMarkerModel(
          month: month,
          measurements: [
            HealthMeasurementModel(
              name: 'Total Cholesterol',
              value: cholesterol,
              unit: 'mg/dL',
            ),
          ],
        ),
      );
    }

    test('loads health markers from multiple months', () async {
      await saveTestMonth(month: '2026-09', cholesterol: 210);

      await saveTestMonth(month: '2026-10', cholesterol: 195);

      await saveTestMonth(month: '2026-11', cholesterol: 180);

      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 9),
        endMonth: DateTime(2026, 11),
      );

      expect(result.length, 3);

      expect(result.map((record) => record.month).toList(), [
        '2026-09',
        '2026-10',
        '2026-11',
      ]);
    });

    test('returns months in chronological order', () async {
      // Save records in reverse order.
      await saveTestMonth(month: '2026-11', cholesterol: 180);

      await saveTestMonth(month: '2026-09', cholesterol: 210);

      await saveTestMonth(month: '2026-10', cholesterol: 195);

      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 9),
        endMonth: DateTime(2026, 11),
      );

      expect(result.map((record) => record.month).toList(), [
        '2026-09',
        '2026-10',
        '2026-11',
      ]);

      expect(result.map((record) => record.measurements.first.value).toList(), [
        210,
        195,
        180,
      ]);
    });

    test('skips months without saved measurements', () async {
      await saveTestMonth(month: '2026-09', cholesterol: 210);

      await saveTestMonth(month: '2026-11', cholesterol: 180);

      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 9),
        endMonth: DateTime(2026, 11),
      );

      expect(result.length, 2);

      expect(result.map((record) => record.month).toList(), [
        '2026-09',
        '2026-11',
      ]);
    });

    test('supports a single-month range', () async {
      await saveTestMonth(month: '2026-10', cholesterol: 195);

      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 10),
        endMonth: DateTime(2026, 10),
      );

      expect(result.length, 1);
      expect(result.first.month, '2026-10');
      expect(result.first.measurements.first.value, 195);
    });

    test('returns empty list when range has no records', () async {
      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 6),
        endMonth: DateTime(2026, 8),
      );

      expect(result, isEmpty);
    });

    test('rejects an invalid month range', () async {
      await expectLater(
        repository.getMarkersForRange(
          startMonth: DateTime(2026, 11),
          endMonth: DateTime(2026, 9),
        ),
        throwsArgumentError,
      );
    });

    test('does not load another user health markers', () async {
      await saveTestMonth(month: '2026-10', cholesterol: 195);

      // Simulate a different authenticated user.
      when(() => user.uid).thenReturn('userB');

      final result = await repository.getMarkersForRange(
        startMonth: DateTime(2026, 10),
        endMonth: DateTime(2026, 10),
      );

      expect(result, isEmpty);
    });
  });
}
