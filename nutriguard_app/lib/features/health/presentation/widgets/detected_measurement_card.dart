import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DetectedMeasurementCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final bool isConfirmed;
  final bool lowConfidence;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onConfirm;

  const DetectedMeasurementCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.isConfirmed,
    required this.onValueChanged,
    required this.onConfirm,
    this.lowConfidence = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EFF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (isConfirmed)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),

          if (lowConfidence) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Unverified OCR result — check against report',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          if (title == 'Blood Pressure') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('systolic'),
                    initialValue: value.split('/').first,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Systolic',
                      hintText: '120',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (systolic) {
                      final parts = value.split('/');
                      final diastolic = parts.length > 1 ? parts[1] : '';
                      onValueChanged('$systolic/$diastolic');
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/'),
                ),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('diastolic'),
                    initialValue: value.contains('/')
                        ? value.split('/').last
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic',
                      hintText: '80',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (diastolic) {
                      final parts = value.split('/');
                      final systolic = parts.first;
                      onValueChanged('$systolic/$diastolic');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Blood pressure unit: $unit',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            TextFormField(
              initialValue: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Detected Value',
                suffixText: unit,
                border: const OutlineInputBorder(),
              ),
              onChanged: onValueChanged,
            ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isConfirmed ? null : onConfirm,
              icon: Icon(isConfirmed ? Icons.check : Icons.verified_outlined),
              label: Text(isConfirmed ? 'Confirmed' : 'Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
