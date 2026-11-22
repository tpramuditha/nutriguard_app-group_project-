import 'package:flutter/material.dart';

import '../../../exercise/data/models/exercise_log_model.dart';
import '../../../exercise/data/repositories/exercise_log_repository.dart';
import '../../domain/services/exercise_adherence_service.dart';

class ExerciseCompletionSection extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ExerciseLogRepository? repository;

  const ExerciseCompletionSection({
    super.key,
    required this.startDate,
    required this.endDate,
    this.repository,
  });

  @override
  State<ExerciseCompletionSection> createState() =>
      _ExerciseCompletionSectionState();
}

class _ExerciseCompletionSectionState extends State<ExerciseCompletionSection> {
  late ExerciseLogRepository _repository;

  final ExerciseAdherenceService _service = const ExerciseAdherenceService();

  late Future<List<ExerciseLogModel>> _exerciseFuture;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? ExerciseLogRepository();

    _loadExercises();
  }

  void _loadExercises() {
    _exerciseFuture = _repository.getExerciseLogsForRange(
      startDate: widget.startDate,
      endDate: widget.endDate,
    );
  }

  @override
  void didUpdateWidget(covariant ExerciseCompletionSection oldWidget) {
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
      _repository = widget.repository ?? ExerciseLogRepository();
    }

    if (repositoryChanged || startChanged || endChanged) {
      _loadExercises();
    }
  }

  void _refresh() {
    setState(_loadExercises);
  }

  Widget _buildStatistics(List<ExerciseLogModel> logs) {
    final result = _service.calculate(
      exerciseLogs: logs,
      startDate: widget.startDate,
      endDate: widget.endDate,
    );

    if (!result.hasData) {
      return const Card(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 36,
                color: Color(0xFF086F67),
              ),
              SizedBox(height: 12),
              Text(
                'No exercise records for this period.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Add planned or completed exercises '
                'to start tracking your activity.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final percentage = result.completionPercentage;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recorded Exercise Completion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF268C82),
                  ),
                ),
                const Spacer(),
                Text(
                  '${result.completedExercises} of '
                  '${result.totalExercises} completed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color(0xFFE2EFEB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF268C82),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statisticTile(
                    title: 'Completed Minutes',
                    value: '${result.completedMinutes} min',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statisticTile(
                    title: 'Planned / Incomplete',
                    value: '${result.plannedExercises}',
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Calculated from saved exercise records '
              'within the selected period. This is a '
              'recorded completion rate, not a measure '
              'of meeting a recommended exercise goal.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF268C82), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF086F67),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
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
                'Exercise Completion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF086F67),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh exercise statistics',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        const SizedBox(height: 8),

        FutureBuilder<List<ExerciseLogModel>>(
          future: _exerciseFuture,
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
                        'Unable to load exercise statistics.',
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

            return _buildStatistics(snapshot.data ?? <ExerciseLogModel>[]);
          },
        ),
      ],
    );
  }
}
