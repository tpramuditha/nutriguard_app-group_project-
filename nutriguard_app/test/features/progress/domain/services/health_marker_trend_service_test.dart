import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';
import 'package:nutriguard_app/features/progress/domain/services/health_marker_trend_service.dart';

void main() {
  const service = HealthMarkerTrendService();

  HealthMeasurementModel measurement(String name, double value, String unit) {
    return HealthMeasurementModel(name: name, value: value, unit: unit);
  }

  MonthlyHealthMarkerModel monthlyRecord(
    String month,
    List<HealthMeasurementModel> measurements,
  ) {
    return MonthlyHealthMarkerModel(month: month, measurements: measurements);
  }

  group('HealthMarkerTrendService', () {
    test('sorts cholesterol measurements by month', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('Total Cholesterol', 180, 'mg/dL'),
        ]),
        monthlyRecord('2026-09', [
          measurement('Total Cholesterol', 210, 'mg/dL'),
        ]),
        monthlyRecord('2026-10', [
          measurement('Total Cholesterol', 195, 'mg/dL'),
        ]),
      ];

      final result = service.getTotalCholesterolTrend(records);

      expect(result.length, 3);
      expect(result.map((p) => p.month).toList(), [
        '2026-09',
        '2026-10',
        '2026-11',
      ]);
      expect(result.map((p) => p.value).toList(), [210, 195, 180]);
    });

    test('returns empty trend when records are empty', () {
      final result = service.getTotalCholesterolTrend([]);

      expect(result, isEmpty);
    });

    test('skips months without requested measurement', () {
      final records = [
        monthlyRecord('2026-09', [
          measurement('Total Cholesterol', 205, 'mg/dL'),
        ]),
        monthlyRecord('2026-10', [
          measurement('LDL Cholesterol', 130, 'mg/dL'),
        ]),
        monthlyRecord('2026-11', [
          measurement('Total Cholesterol', 180, 'mg/dL'),
        ]),
      ];

      final result = service.getTotalCholesterolTrend(records);

      expect(result.length, 2);
      expect(result[0].month, '2026-09');
      expect(result[1].month, '2026-11');
    });

    test('preserves measurement values and units', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('Fasting Blood Glucose', 92.5, 'mg/dL'),
        ]),
      ];

      final result = service.getFastingGlucoseTrend(records);

      expect(result.length, 1);
      expect(result.first.value, 92.5);
      expect(result.first.unit, 'mg/dL');
      expect(result.first.measurementName, 'Fasting Blood Glucose');
    });

    test('does not mix fasting and random glucose', () {
      final records = [
        monthlyRecord('2026-10', [
          measurement('Random Blood Glucose', 135, 'mg/dL'),
        ]),
        monthlyRecord('2026-11', [
          measurement('Fasting Blood Glucose', 95, 'mg/dL'),
        ]),
      ];

      final result = service.getFastingGlucoseTrend(records);

      expect(result.length, 1);
      expect(result.first.month, '2026-11');
      expect(result.first.value, 95);
    });

    test('extracts systolic blood pressure only', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('Systolic Blood Pressure', 125, 'mmHg'),
          measurement('Diastolic Blood Pressure', 82, 'mmHg'),
        ]),
      ];

      final result = service.getSystolicPressureTrend(records);

      expect(result.length, 1);
      expect(result.first.value, 125);
      expect(result.first.unit, 'mmHg');
    });

    test('extracts diastolic blood pressure only', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('Systolic Blood Pressure', 125, 'mmHg'),
          measurement('Diastolic Blood Pressure', 82, 'mmHg'),
        ]),
      ];

      final result = service.getDiastolicPressureTrend(records);

      expect(result.length, 1);
      expect(result.first.value, 82);
      expect(result.first.unit, 'mmHg');
    });

    test('supports custom measurement names', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('LDL Cholesterol', 110, 'mg/dL'),
        ]),
      ];

      final result = service.getTrend(
        monthlyRecords: records,
        measurementName: 'LDL Cholesterol',
      );

      expect(result.length, 1);
      expect(result.first.measurementName, 'LDL Cholesterol');
      expect(result.first.value, 110);
    });

    test('returns empty when requested measurement is missing', () {
      final records = [
        monthlyRecord('2026-11', [
          measurement('Total Cholesterol', 180, 'mg/dL'),
        ]),
      ];

      final result = service.getFastingGlucoseTrend(records);

      expect(result, isEmpty);
    });
  });
}
