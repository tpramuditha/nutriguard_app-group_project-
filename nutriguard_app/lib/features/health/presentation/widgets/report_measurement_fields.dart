import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ReportMeasurementFields extends StatelessWidget {
  final String reportType;

  // Sends measurement values to the parent page.
  final void Function(String measurementName, String value, String unit)
  onMeasurementChanged;

  const ReportMeasurementFields({
    super.key,
    required this.reportType,
    required this.onMeasurementChanged,
  });

  static const Map<String, List<Map<String, String>>> reportFields = {
    'Lipid Profile': [
      {'name': 'Total Cholesterol', 'unit': 'mg/dL'},
      {'name': 'LDL Cholesterol', 'unit': 'mg/dL'},
      {'name': 'HDL Cholesterol', 'unit': 'mg/dL'},
      {'name': 'Triglycerides', 'unit': 'mg/dL'},
    ],
    'Blood Glucose / HbA1c': [
      {'name': 'Fasting Blood Glucose', 'unit': 'mg/dL'},
      {'name': 'HbA1c', 'unit': '%'},
    ],
    'Kidney Function': [
      {'name': 'Creatinine', 'unit': 'mg/dL'},
      {'name': 'eGFR', 'unit': 'mL/min/1.73 m²'},
      {'name': 'Urea', 'unit': 'mg/dL'},
    ],
    'Liver Function': [
      {'name': 'ALT', 'unit': 'U/L'},
      {'name': 'AST', 'unit': 'U/L'},
      {'name': 'Bilirubin', 'unit': 'mg/dL'},
    ],
    'Thyroid Profile': [
      {'name': 'TSH', 'unit': 'mIU/L'},
      {'name': 'Free T4', 'unit': 'ng/dL'},
    ],
    'Complete Blood Count': [
      {'name': 'Hemoglobin', 'unit': 'g/dL'},
      {'name': 'WBC', 'unit': '10³/µL'},
      {'name': 'Platelets', 'unit': '10³/µL'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final fields = reportFields[reportType];

    if (fields == null) {
      return const Text(
        'Custom measurement fields will be added next.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in fields) ...[
          Text(
            field['name']!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            key: ValueKey('$reportType-${field['name']}'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter value from your report',
              suffixText: field['unit'],
            ),
            onChanged: (value) {
              onMeasurementChanged(field['name']!, value, field['unit']!);
            },
          ),

          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
