import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/health/data/models/health_measurement_model.dart';
import 'package:nutriguard_app/features/health/data/models/monthly_health_marker_model.dart';

void main() {
  test('converts monthly health markers to a Firestore map', () {
    const marker = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Total Cholesterol',
          value: 185,
          unit: 'mg/dL',
        ),
        HealthMeasurementModel(
          name: 'Fasting Blood Glucose',
          value: 95,
          unit: 'mg/dL',
        ),
      ],
    );

    final map = marker.toMap();

    expect(map['month'], '2026-10');

    final measurements = map['measurements'] as List;

    expect(measurements.length, 2);
    expect(measurements[0]['name'], 'Total Cholesterol');
    expect(measurements[0]['value'], 185);
    expect(measurements[1]['value'], 95);
  });

  test('reconstructs monthly markers from a Firestore map', () {
    final map = {
      'month': '2026-10',
      'measurements': [
        {'name': 'Systolic Blood Pressure', 'value': 120, 'unit': 'mmHg'},
        {'name': 'Diastolic Blood Pressure', 'value': 80, 'unit': 'mmHg'},
      ],
    };

    final marker = MonthlyHealthMarkerModel.fromMap(map);

    expect(marker.month, '2026-10');
    expect(marker.measurements.length, 2);
    expect(marker.measurements[0].value, 120);
    expect(marker.measurements[1].unit, 'mmHg');
  });

  test('keeps missing measurements absent', () {
    const marker = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'HDL Cholesterol',
          value: 55,
          unit: 'mg/dL',
        ),
      ],
    );

    final restored = MonthlyHealthMarkerModel.fromMap(marker.toMap());

    expect(restored.measurements.length, 1);
    expect(restored.measurements.first.name, 'HDL Cholesterol');
  });

  test('preserves decimal measurement values', () {
    const marker = MonthlyHealthMarkerModel(
      month: '2026-10',
      measurements: [
        HealthMeasurementModel(
          name: 'Blood Glucose',
          value: 95.5,
          unit: 'mg/dL',
        ),
      ],
    );

    final restored = MonthlyHealthMarkerModel.fromMap(marker.toMap());

    expect(restored.measurements.first.value, 95.5);
  });
}
