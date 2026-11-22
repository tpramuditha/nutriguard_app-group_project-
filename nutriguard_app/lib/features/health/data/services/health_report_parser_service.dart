import '../models/health_measurement_model.dart';

class HealthReportParserService {
  // Only measurement names we explicitly recognize.
  static const Map<String, List<String>> _testNames = {
    'Total Cholesterol': ['total cholesterol', 'cholesterol total'],
    'LDL Cholesterol': ['ldl cholesterol', 'ldl-c'],
    'HDL Cholesterol': ['hdl cholesterol', 'hdl-c'],
    'Triglycerides': ['triglycerides'],
    'Fasting Blood Glucose': [
      'fasting blood glucose',
      'fasting glucose',
      'fasting blood sugar',
      'fbs',
    ],

    'Random Blood Glucose': [
      'random blood glucose',
      'random glucose',
      'random blood sugar',
      'rbs',
    ],
  };

  List<HealthMeasurementModel> extractMeasurements(String rawText) {
    final measurements = <HealthMeasurementModel>[];

    // Conservative: only accept a number immediately
    // followed by an explicitly recognized unit.
    final valuePattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(mg/dl|mmol/l)',
      caseSensitive: false,
    );

    for (final line in rawText.split(RegExp(r'\r?\n'))) {
      final text = line.trim();
      final lowerText = text.toLowerCase();

      // Skip lines containing reference-range labels.
      if (lowerText.contains('reference') ||
          lowerText.contains('normal range')) {
        continue;
      }

      // Ambiguous lines with multiple measured values
      // must be reviewed manually.
      final matches = valuePattern.allMatches(text).toList();
      if (matches.length != 1) continue;

      final match = matches.first;
      final beforeValue = lowerText.substring(0, match.start).trim();

      // The value must follow the measurement name.
      if (beforeValue.isEmpty) continue;

      String? detectedName;

      for (final entry in _testNames.entries) {
        if (entry.value.any((alias) => beforeValue == alias)) {
          detectedName = entry.key;
          break;
        }
      }

      if (detectedName == null) continue;

      // Avoid duplicates until we implement a more
      // advanced report interpretation workflow.
      if (measurements.any((item) => item.name == detectedName)) {
        continue;
      }

      final value = double.tryParse(match.group(1)!);
      if (value == null || !value.isFinite) continue;

      final unit = match.group(2)!;

      measurements.add(
        HealthMeasurementModel(name: detectedName, value: value, unit: unit),
      );
    }

    return measurements;
  }
}
