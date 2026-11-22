import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/health_report_model.dart';

class HealthReportDetailPage extends StatelessWidget {
  final HealthReportModel report;

  const HealthReportDetailPage({super.key, required this.report});

  String get _formattedDate {
    final day = report.reportDate.day.toString().padLeft(2, '0');
    final month = report.reportDate.month.toString().padLeft(2, '0');

    return '$day/$month/${report.reportDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Health Report Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.reportName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report Type: ${report.reportType}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report Date: $_formattedDate',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Report Measurements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 12),

            for (final measurement in report.measurements)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0EFF2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        measurement.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '${measurement.value} ${measurement.unit}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            const Text(
              'These are recorded laboratory values. '
              'They are not a medical diagnosis. '
              'Consult a qualified healthcare professional '
              'for interpretation.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
