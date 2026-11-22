class ExerciseRecommendationModel {
  final String id;
  final String name;
  final String type;
  final String intensity;
  final int durationMinutes;
  final String description;
  final List<String> benefits;
  final List<String> safetyNotes;

  const ExerciseRecommendationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.intensity,
    required this.durationMinutes,
    required this.description,
    required this.benefits,
    required this.safetyNotes,
  });

  ExerciseRecommendationModel copyWith({
    String? id,
    String? name,
    String? type,
    String? intensity,
    int? durationMinutes,
    String? description,
    List<String>? benefits,
    List<String>? safetyNotes,
  }) {
    return ExerciseRecommendationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      safetyNotes: safetyNotes ?? this.safetyNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'intensity': intensity,
      'durationMinutes': durationMinutes,
      'description': description,
      'benefits': benefits,
      'safetyNotes': safetyNotes,
    };
  }

  factory ExerciseRecommendationModel.fromMap(Map<String, dynamic> map) {
    return ExerciseRecommendationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      intensity: map['intensity'] as String,
      durationMinutes: map['durationMinutes'] as int,
      description: map['description'] as String,
      benefits: List<String>.from(map['benefits'] as List),
      safetyNotes: List<String>.from(map['safetyNotes'] as List),
    );
  }
}
