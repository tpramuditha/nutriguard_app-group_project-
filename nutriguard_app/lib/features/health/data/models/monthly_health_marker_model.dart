import 'health_measurement_model.dart';

class MonthlyHealthMarkerModel {
  final String month;
  final List<HealthMeasurementModel> measurements;

  const MonthlyHealthMarkerModel({
    required this.month,
    required this.measurements,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'measurements': measurements
          .map((measurement) => measurement.toMap())
          .toList(),
    };
  }

  factory MonthlyHealthMarkerModel.fromMap(Map<String, dynamic> map) {
    final rawMeasurements = map['measurements'] as List<dynamic>;

    return MonthlyHealthMarkerModel(
      month: map['month'] as String,
      measurements: rawMeasurements
          .map(
            (item) => HealthMeasurementModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
