import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HealthFilterBanner extends StatelessWidget {
  final List<String> healthMarkers;

  const HealthFilterBanner({super.key, required this.healthMarkers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF7ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              healthMarkers.isEmpty
                  ? 'No health markers selected'
                  : 'Filtered for: ${healthMarkers.join(', ')}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Health-Aware Suggestions'),
                  content: const Text(
                    'This is a preview of the health-filtering UI. '
                    'Actual rule-based filtering will be implemented later.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
