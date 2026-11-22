import '../../../health/data/models/monthly_health_marker_model.dart';
import '../../../health/data/repositories/monthly_health_marker_repository.dart';

typedef HealthMarkerFetcher = Future<MonthlyHealthMarkerModel?> Function(
  String month,
);

class RecipeHealthMarkerLoader {
  final HealthMarkerFetcher _fetchMarkers;

  RecipeHealthMarkerLoader({
    MonthlyHealthMarkerRepository? repository,
    HealthMarkerFetcher? fetchMarkers,
  }) : _fetchMarkers =
           fetchMarkers ??
           (repository ?? MonthlyHealthMarkerRepository()).getMarkers;

  Future<MonthlyHealthMarkerModel?> loadMarkers({required String month}) async {
    // Existing Firestore month format: yyyy-MM
    final validMonth = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

    if (!validMonth.hasMatch(month)) {
      throw ArgumentError('Month must use yyyy-MM format.');
    }

    return _fetchMarkers(month);
  }

  Future<List<String>> getRecordedMeasurementNames({
    required String month,
  }) async {
    final markers = await loadMarkers(month: month);

    if (markers == null) {
      return [];
    }

    return markers.measurements.map((measurement) => measurement.name).toList();
  }

  Future<bool> hasHealthData({required String month}) async {
    final markers = await loadMarkers(month: month);

    return markers != null && markers.measurements.isNotEmpty;
  }
}
