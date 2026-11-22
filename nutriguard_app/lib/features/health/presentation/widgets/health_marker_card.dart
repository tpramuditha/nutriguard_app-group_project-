import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HealthMarkerCard extends StatelessWidget {
  final String title;
  final String value;
  final String lastLogged;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const HealthMarkerCard({
    super.key,
    required this.title,
    required this.value,
    required this.lastLogged,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0EFF2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(icon, color: iconColor, size: 27),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      lastLogged,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
