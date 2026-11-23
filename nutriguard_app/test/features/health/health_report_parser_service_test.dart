import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguard_app/features/health/data/services/health_report_parser_service.dart';

void main() {
  final parser = HealthReportParserService();

  test('extracts supported lipid measurements', () {
    const text = '''
Total Cholesterol 185 mg/dL
LDL Cholesterol 110 mg/dL
HDL Cholesterol 55 mg/dL
Triglycerides 125 mg/dL
''';

    final result = parser.extractMeasurements(text);

    expect(result.length, 4);
    expect(result[0].name, 'Total Cholesterol');
    expect(result[0].value, 185);
    expect(result[0].unit, 'mg/dL');
    expect(result[3].name, 'Triglycerides');
    expect(result[3].value, 125);
  });

  test('ignores unsupported and unrelated text', () {
    const text = '''
Sample laboratory report
Patient ID 12345
Date 14/10/2026
RANDOM BLOOD SUGAR
Follow medical guidelines
''';

    final result = parser.extractMeasurements(text);

    expect(result, isEmpty);
  });

  test('skips ambiguous lines with multiple values', () {
    const text = 'Total Cholesterol 185 mg/dL 200 mg/dL';

    final result = parser.extractMeasurements(text);

    expect(result, isEmpty);
  });

  test('recognizes fasting glucose with a unit', () {
    const text = 'Fasting Glucose 95 mg/dL';

    final result = parser.extractMeasurements(text);

    expect(result.length, 1);
    expect(result.first.name, 'Fasting Blood Glucose');
    expect(result.first.value, 95);
  });

  test('recognizes random blood glucose with a result', () {
    const text = 'Random Blood Glucose 108 mg/dL';

    final result = parser.extractMeasurements(text);

    expect(result.length, 1);
    expect(result.first.name, 'Random Blood Glucose');
    expect(result.first.value, 108);
    expect(result.first.unit.toLowerCase(), 'mg/dl');
  });

  test('does not confuse glucose reference range with result', () {
    const text = '''
Random Blood Glucose
Reference Range 70-140 mg/dL
Normal blood glucose 70-140 mg/dL
''';

    final result = parser.extractMeasurements(text);

    expect(result, isEmpty);
  });
}
