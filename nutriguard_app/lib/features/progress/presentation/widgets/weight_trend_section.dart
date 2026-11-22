import 'package:flutter/material.dart';

import '../../../weight/data/models/weight_log_model.dart';
import '../../../weight/data/repositories/weight_log_repository.dart';

import '../../domain/services/weight_trend_service.dart';
import 'weight_trend_chart.dart';

class WeightTrendSection extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final WeightLogRepository? repository;

  const WeightTrendSection({
    super.key,
    required this.startDate,
    required this.endDate,
    this.repository,
  });

  @override
  State<WeightTrendSection> createState() => _WeightTrendSectionState();
}

class _WeightTrendSectionState extends State<WeightTrendSection> {
  late WeightLogRepository _repository;

  final WeightTrendService _trendService = const WeightTrendService();

  late Future<List<WeightLogModel>> _weightFuture;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? WeightLogRepository();

    _loadWeights();
  }

  void _loadWeights() {
    _weightFuture = _repository.getWeightLogsForRange(
      startDate: widget.startDate,
      endDate: widget.endDate,
    );
  }

  @override
  void didUpdateWidget(covariant WeightTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final repositoryChanged = oldWidget.repository != widget.repository;

    final startChanged =
        oldWidget.startDate.year != widget.startDate.year ||
        oldWidget.startDate.month != widget.startDate.month ||
        oldWidget.startDate.day != widget.startDate.day;

    final endChanged =
        oldWidget.endDate.year != widget.endDate.year ||
        oldWidget.endDate.month != widget.endDate.month ||
        oldWidget.endDate.day != widget.endDate.day;

    if (repositoryChanged) {
      _repository = widget.repository ?? WeightLogRepository();
    }

    if (repositoryChanged || startChanged || endChanged) {
      _loadWeights();
    }
  }

  void _refresh() {
    setState(_loadWeights);
  }

  Widget _buildChart(List<WeightLogModel> logs) {
    final result = _trendService.calculate(
      weightLogs: logs,
      startDate: widget.startDate,
      endDate: widget.endDate,
    );

    return WeightTrendChart(result: result);
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
                'Weight Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF086F67),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh weight trend',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<WeightLogModel>>(
          future: _weightFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Unable to load weight history.',
                        textAlign: TextAlign.center,
                      ),
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

            return _buildChart(snapshot.data ?? <WeightLogModel>[]);
          },
        ),
      ],
    );
  }
}
