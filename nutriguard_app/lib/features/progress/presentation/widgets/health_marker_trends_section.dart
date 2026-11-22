import 'package:flutter/material.dart';

import '../../../health/data/models/monthly_health_marker_model.dart';
import '../../../health/data/repositories/monthly_health_marker_repository.dart';

import '../../domain/services/health_marker_trend_service.dart';
import 'health_marker_trend_chart.dart';

class HealthMarkerTrendsSection extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final MonthlyHealthMarkerRepository? repository;

  const HealthMarkerTrendsSection({
    super.key,
    required this.startDate,
    required this.endDate,
    this.repository,
  });

  @override
  State<HealthMarkerTrendsSection> createState() =>
      _HealthMarkerTrendsSectionState();
}

class _HealthMarkerTrendsSectionState extends State<HealthMarkerTrendsSection> {
  late MonthlyHealthMarkerRepository _repository;

  final HealthMarkerTrendService _trendService =
      const HealthMarkerTrendService();

  late Future<List<MonthlyHealthMarkerModel>> _markersFuture;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? MonthlyHealthMarkerRepository();

    _loadMarkers();
  }

  void _loadMarkers() {
    _markersFuture = _repository.getMarkersForRange(
      startMonth: widget.startDate,
      endMonth: widget.endDate,
    );
  }

  @override
  void didUpdateWidget(covariant HealthMarkerTrendsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final repositoryChanged = oldWidget.repository != widget.repository;

    if (repositoryChanged) {
      _repository = widget.repository ?? MonthlyHealthMarkerRepository();
    }

    final startChanged =
        oldWidget.startDate.year != widget.startDate.year ||
        oldWidget.startDate.month != widget.startDate.month;

    final endChanged =
        oldWidget.endDate.year != widget.endDate.year ||
        oldWidget.endDate.month != widget.endDate.month;

    if (repositoryChanged || startChanged || endChanged) {
      _loadMarkers();
    }
  }

  void _refresh() {
    setState(_loadMarkers);
  }

  Widget _buildCharts(List<MonthlyHealthMarkerModel> records) {
    final cholesterol = _trendService.getTotalCholesterolTrend(records);

    final glucose = _trendService.getFastingGlucoseTrend(records);

    final systolic = _trendService.getSystolicPressureTrend(records);

    final diastolic = _trendService.getDiastolicPressureTrend(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HealthMarkerTrendChart(
          title: 'Total Cholesterol Trend',
          points: cholesterol,
          lineColor: const Color(0xFFFF7043),
        ),
        const SizedBox(height: 12),
        HealthMarkerTrendChart(
          title: 'Fasting Blood Glucose Trend',
          points: glucose,
          lineColor: const Color(0xFF2389E8),
        ),
        const SizedBox(height: 12),
        HealthMarkerTrendChart(
          title: 'Systolic Blood Pressure Trend',
          points: systolic,
          lineColor: const Color(0xFFF04468),
        ),
        const SizedBox(height: 12),
        HealthMarkerTrendChart(
          title: 'Diastolic Blood Pressure Trend',
          points: diastolic,
          lineColor: const Color(0xFF9464CB),
        ),
        const SizedBox(height: 10),
        const Text(
          'Measurements are displayed for tracking only. '
          'They are not a medical diagnosis. '
          'Consult a healthcare professional for interpretation.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Health Markers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF086F67),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh health markers',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<MonthlyHealthMarkerModel>>(
          future: _markersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Unable to load health marker history.'),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final records = snapshot.data ?? <MonthlyHealthMarkerModel>[];

            if (records.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        size: 36,
                        color: Color(0xFF086F67),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No health marker records available '
                        'for this period.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildCharts(records);
          },
        ),
      ],
    );
  }
}
