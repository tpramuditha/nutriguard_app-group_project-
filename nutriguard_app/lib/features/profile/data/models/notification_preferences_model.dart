class NotificationPreferencesModel {
  final bool mealReminders;
  final bool monthlyHealthMarkerReminders;
  final bool aiSuggestionAlerts;

  const NotificationPreferencesModel({
    required this.mealReminders,
    required this.monthlyHealthMarkerReminders,
    required this.aiSuggestionAlerts,
  });

  static const NotificationPreferencesModel defaultPreferences =
      NotificationPreferencesModel(
        mealReminders: true,
        monthlyHealthMarkerReminders: true,
        aiSuggestionAlerts: false,
      );

  Map<String, dynamic> toMap() {
    return {
      'mealReminders': mealReminders,
      'monthlyHealthMarkerReminders': monthlyHealthMarkerReminders,
      'aiSuggestionAlerts': aiSuggestionAlerts,
    };
  }

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel(
      mealReminders: map['mealReminders'] is bool
          ? map['mealReminders'] as bool
          : defaultPreferences.mealReminders,
      monthlyHealthMarkerReminders: map['monthlyHealthMarkerReminders'] is bool
          ? map['monthlyHealthMarkerReminders'] as bool
          : defaultPreferences.monthlyHealthMarkerReminders,
      aiSuggestionAlerts: map['aiSuggestionAlerts'] is bool
          ? map['aiSuggestionAlerts'] as bool
          : defaultPreferences.aiSuggestionAlerts,
    );
  }
}
