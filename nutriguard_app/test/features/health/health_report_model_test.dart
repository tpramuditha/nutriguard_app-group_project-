import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/health_report_model.dart';

void main() {
  group('HealthMeasurementModel', () {
    test('converts measurement to Map correctly', () {
      const measurement = HealthMeasurementModel(
        name: 'Creatinine',
        value: 1.2,
        unit: 'mg/dL',
      );

      final map = measurement.toMap();

      expect(map['name'], 'Creatinine');
      expect(map['value'], 1.2);
      expect(map['unit'], 'mg/dL');
    });

    test('creates measurement from Map correctly', () {
      final map = {'name': 'Vitamin D', 'value': 35, 'unit': 'ng/mL'};

      final measurement = HealthMeasurementModel.fromMap(map);

      expect(measurement.name, 'Vitamin D');
      expect(measurement.value, 35.0);
      expect(measurement.unit, 'ng/mL');
    });

    test('measurement preserves values after round trip', () {
      const original = HealthMeasurementModel(
        name: 'eGFR',
        value: 85,
        unit: 'mL/min/1.73 m²',
      );

      final restored = HealthMeasurementModel.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.value, original.value);
      expect(restored.unit, original.unit);
    });
  });

  group('HealthReportModel', () {
    test('converts complete report to Map correctly', () {
      final report = HealthReportModel(
        reportType: 'Kidney Function',
        reportName: 'Kidney Function',
        reportDate: DateTime(2026, 10, 14),
        measurements: const [
          HealthMeasurementModel(name: 'Creatinine', value: 1.2, unit: 'mg/dL'),
          HealthMeasurementModel(
            name: 'eGFR',
            value: 85,
            unit: 'mL/min/1.73 m²',
          ),
        ],
      );

      final map = report.toMap();

      expect(map['reportType'], 'Kidney Function');
      expect(map['reportName'], 'Kidney Function');
      expect(map['reportDate'], '2026-10-14T00:00:00.000');

      final measurements = map['measurements'] as List;

      expect(measurements.length, 2);
      expect(measurements[0]['name'], 'Creatinine');
      expect(measurements[1]['name'], 'eGFR');
    });

    test('complete report preserves data after round trip', () {
      final original = HealthReportModel(
        reportType: 'Custom Report',
        reportName: 'Vitamin Test',
        reportDate: DateTime(2026, 10, 13),
        measurements: const [
          HealthMeasurementModel(name: 'Vitamin D', value: 35, unit: 'ng/mL'),
          HealthMeasurementModel(
            name: 'Vitamin B12',
            value: 450,
            unit: 'pg/mL',
          ),
        ],
      );

      final map = original.toMap();

      final restored = HealthReportModel.fromMap(map);

      expect(restored.reportType, original.reportType);
      expect(restored.reportName, original.reportName);
      expect(restored.reportDate, original.reportDate);

      expect(restored.measurements.length, 2);

      expect(restored.measurements[0].name, 'Vitamin D');
      expect(restored.measurements[0].value, 35);
      expect(restored.measurements[0].unit, 'ng/mL');

      expect(restored.measurements[1].name, 'Vitamin B12');
      expect(restored.measurements[1].value, 450);
      expect(restored.measurements[1].unit, 'pg/mL');
    });

    test('supports reports containing one measurement', () {
      final original = HealthReportModel(
        reportType: 'Lipid Profile',
        reportName: 'Lipid Profile',
        reportDate: DateTime(2026, 10, 14),
        measurements: const [
          HealthMeasurementModel(
            name: 'Total Cholesterol',
            value: 180,
            unit: 'mg/dL',
          ),
        ],
      );

      final restored = HealthReportModel.fromMap(original.toMap());

      expect(restored.measurements.length, 1);
      expect(restored.measurements.first.name, 'Total Cholesterol');
      expect(restored.measurements.first.value, 180);
    });
  });
}
