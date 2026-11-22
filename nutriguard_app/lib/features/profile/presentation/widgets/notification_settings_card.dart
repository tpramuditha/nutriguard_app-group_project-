import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationSettingsCard extends StatelessWidget {
  final bool mealReminders;
  final bool monthlyHealthMarkerReminders;
  final bool aiSuggestionAlerts;
  final Future<void> Function(String setting, bool value) onChanged;
  final bool enabled;

  const NotificationSettingsCard({
    super.key,
    required this.mealReminders,
    required this.monthlyHealthMarkerReminders,
    required this.aiSuggestionAlerts,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _notificationSwitch(
            title: 'Meal Logging Reminders',
            value: mealReminders,
            setting: 'mealReminders',
          ),

          const Divider(),

          _notificationSwitch(
            title: 'Monthly Health Marker Reminder',
            value: monthlyHealthMarkerReminders,
            setting: 'monthlyHealthMarkerReminders',
          ),

          const Divider(),

          _notificationSwitch(
            title: 'AI Suggestion Alerts',
            value: aiSuggestionAlerts,
            setting: 'aiSuggestionAlerts',
          ),
        ],
      ),
    );
  }

  Widget _notificationSwitch({
    required String title,
    required bool value,
    required String setting,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled
              ? (newValue) => onChanged(setting, newValue)
              : null,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
