import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/health_measurement_model.dart';

class HealthMarkerDetailPage extends StatelessWidget {
  final String title;
  final String monthLabel;
  final List<HealthMeasurementModel> measurements;
  final List<String> expectedNames;

  const HealthMarkerDetailPage({
    super.key,
    required this.title,
    required this.monthLabel,
    required this.measurements,
    required this.expectedNames,
  });

  String _formatValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: Text('$title Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0EFF2)),
            ),
            child: Column(
              children: [
                for (final name in expectedNames) ...[
                  Builder(
                    builder: (context) {
                      HealthMeasurementModel? recorded;

                      for (final measurement in measurements) {
                        if (measurement.name == name) {
                          recorded = measurement;
                          break;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              recorded == null
                                  ? 'Not recorded'
                                  : '${_formatValue(recorded.value)} '
                                        '${recorded.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (name != expectedNames.last) const Divider(height: 1),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'These measurements are self-reported. '
            'NutriGuard does not automatically classify them '
            'as normal or abnormal.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
