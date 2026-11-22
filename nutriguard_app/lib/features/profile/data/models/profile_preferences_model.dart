class ProfilePreferencesModel {
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final String unitSystem;

  ProfilePreferencesModel({
    required List<String> dietaryRestrictions,
    required List<String> allergies,
    required this.unitSystem,
  }) : dietaryRestrictions = List.unmodifiable(dietaryRestrictions),
       allergies = List.unmodifiable(allergies);

  static final ProfilePreferencesModel defaultPreferences =
      ProfilePreferencesModel(
        dietaryRestrictions: ['None'],
        allergies: [],
        unitSystem: 'Metric',
      );

  static const List<String> allowedRestrictions = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Pescatarian',
    'None',
  ];

  static const List<String> allowedUnitSystems = ['Metric', 'Imperial'];

  Map<String, dynamic> toMap() {
    return {
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'unitSystem': unitSystem,
    };
  }

  factory ProfilePreferencesModel.fromMap(Map<String, dynamic> map) {
    final rawRestrictions = map['dietaryRestrictions'];
    final rawAllergies = map['allergies'];
    final rawUnitSystem = map['unitSystem'];

    final restrictions = rawRestrictions is List
        ? rawRestrictions.whereType<String>().toList()
        : defaultPreferences.dietaryRestrictions;

    final allergies = rawAllergies is List
        ? rawAllergies.whereType<String>().toList()
        : defaultPreferences.allergies;

    final validRestrictions =
        restrictions.isNotEmpty &&
        restrictions.every(allowedRestrictions.contains) &&
        !(restrictions.contains('None') && restrictions.length > 1);

    return ProfilePreferencesModel(
      dietaryRestrictions: validRestrictions
          ? restrictions
          : defaultPreferences.dietaryRestrictions,
      allergies: allergies.length <= 30
          ? allergies
          : defaultPreferences.allergies,
      unitSystem: allowedUnitSystems.contains(rawUnitSystem)
          ? rawUnitSystem as String
          : defaultPreferences.unitSystem,
    );
  }
}
