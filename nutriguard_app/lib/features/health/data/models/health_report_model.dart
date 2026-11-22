import 'health_measurement_model.dart';

class HealthReportModel {
  final String reportType;
  final String reportName;
  final DateTime reportDate;
  final List<HealthMeasurementModel> measurements;

  const HealthReportModel({
    required this.reportType,
    required this.reportName,
    required this.reportDate,
    required this.measurements,
  });

  // Convert entire report to a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'reportType': reportType,
      'reportName': reportName,
      'reportDate': reportDate.toIso8601String(),
      'measurements': measurements
          .map((measurement) => measurement.toMap())
          .toList(),
    };
  }

  // Reconstruct a report from stored data.
  factory HealthReportModel.fromMap(Map<String, dynamic> map) {
    final measurementData = map['measurements'] as List<dynamic>;

    return HealthReportModel(
      reportType: map['reportType'] as String,
      reportName: map['reportName'] as String,
      reportDate: DateTime.parse(map['reportDate'] as String),
      measurements: measurementData.map((item) {
        return HealthMeasurementModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
    );
  }
}
