import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/health_report_model.dart';

class HealthReportCard extends StatelessWidget {
  final HealthReportModel report;
  final VoidCallback onTap;

  const HealthReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  String get formattedDate {
    final day = report.reportDate.day.toString().padLeft(2, '0');
    final month = report.reportDate.month.toString().padLeft(2, '0');

    return '$day/$month/${report.reportDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0EFF2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE2F5EF),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$formattedDate · '
                        '${report.measurements.length} measurements',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
