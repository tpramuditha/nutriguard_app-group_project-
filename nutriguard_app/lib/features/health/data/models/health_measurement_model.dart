class HealthMeasurementModel {
  final String name;
  final double value;
  final String unit;

  const HealthMeasurementModel({
    required this.name,
    required this.value,
    required this.unit,
  });

  // Convert model to Map for Firestore.
  Map<String, dynamic> toMap() {
    return {'name': name, 'value': value, 'unit': unit};
  }

  // Create model from stored Map.
  factory HealthMeasurementModel.fromMap(Map<String, dynamic> map) {
    return HealthMeasurementModel(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }
}
