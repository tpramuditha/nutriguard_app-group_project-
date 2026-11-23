import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';
import 'package:nutriguard_app/features/pantry/data/services/recipe_health_marker_loader.dart';

void main() {
  MonthlyHealthMarkerModel sampleMarkers() {
    return const MonthlyHealthMarkerModel(
      month: '2026-11',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 190,
          unit: 'mg/dL',
        ),
        HealthMeasurementModel(
          name: 'Fasting Blood Glucose',
          value: 95,
          unit: 'mg/dL',
        ),
        HealthMeasurementModel(
          name: 'Systolic Blood Pressure',
          value: 120,
          unit: 'mmHg',
        ),
        HealthMeasurementModel(
          name: 'Diastolic Blood Pressure',
          value: 80,
          unit: 'mmHg',
        ),
      ],
    );
  }

  group('RecipeHealthMarkerLoader', () {
    test('loads existing monthly markers', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async {
          expect(month, '2026-11');
          return sampleMarkers();
        },
      );

      final result = await loader.loadMarkers(month: '2026-11');

      expect(result, isNotNull);
      expect(result!.month, '2026-11');
      expect(result.measurements.length, 4);
    });

    test('returns null when month has no records', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => null,
      );

      final result = await loader.loadMarkers(month: '2026-10');

      expect(result, isNull);
    });

    test('retrieves recorded measurement names', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => sampleMarkers(),
      );

      final names = await loader.getRecordedMeasurementNames(month: '2026-11');

      expect(names.length, 4);
      expect(names, contains('Total Cholesterol'));
      expect(names, contains('Fasting Blood Glucose'));
      expect(names, contains('Systolic Blood Pressure'));
      expect(names, contains('Diastolic Blood Pressure'));
    });

    test('returns empty names when records are absent', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => null,
      );

      final names = await loader.getRecordedMeasurementNames(month: '2026-11');

      expect(names, isEmpty);
    });

    test('reports health data as available', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => sampleMarkers(),
      );

      final hasData = await loader.hasHealthData(month: '2026-11');

      expect(hasData, isTrue);
    });

    test('reports no health data for missing month', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => null,
      );

      final hasData = await loader.hasHealthData(month: '2026-10');

      expect(hasData, isFalse);
    });

    test('reports no health data for empty measurements', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async {
          return const MonthlyHealthMarkerModel(
            month: '2026-11',
            measurements: [],
          );
        },
      );

      final hasData = await loader.hasHealthData(month: '2026-11');

      expect(hasData, isFalse);
    });

    test('rejects empty month', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => sampleMarkers(),
      );

      await expectLater(loader.loadMarkers(month: ''), throwsArgumentError);
    });

    test('rejects invalid month format', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => sampleMarkers(),
      );

      await expectLater(
        loader.loadMarkers(month: 'November 2026'),
        throwsArgumentError,
      );
    });

    test('rejects invalid month number', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async => sampleMarkers(),
      );

      await expectLater(
        loader.loadMarkers(month: '2026-13'),
        throwsArgumentError,
      );
    });

    test('propagates repository loading errors', () async {
      final loader = RecipeHealthMarkerLoader(
        fetchMarkers: (month) async {
          throw StateError('Simulated database error');
        },
      );

      await expectLater(loader.loadMarkers(month: '2026-11'), throwsStateError);
    });
  });
}
