import 'package:flutter/material.dart';

import '../../data/models/exercise_log_model.dart';
import '../../data/repositories/exercise_log_repository.dart';
import '../../../exercise_recommendation/data/models/exercise_recommendation_model.dart';
import '../../../exercise_recommendation/domain/models/exercise_session_arguments.dart';
import 'add_exercise_page.dart';

class ExerciseHistoryPage extends StatefulWidget {
  const ExerciseHistoryPage({super.key});

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  final ExerciseLogRepository _repository = ExerciseLogRepository();

  late Future<List<ExerciseLogModel>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  bool _openedRecommendedExercise = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_openedRecommendedExercise) {
      return;
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;

    ExerciseRecommendationModel? recommendation;
    DateTime? plannedDate;

    if (arguments is ExerciseSessionArguments) {
      recommendation = arguments.recommendation;
      plannedDate = arguments.plannedDate;
    } else if (arguments is ExerciseRecommendationModel) {
      // Preserve previous route argument support.
      recommendation = arguments;
    } else {
      return;
    }

    _openedRecommendedExercise = true;

    final selectedRecommendation = recommendation;
    final selectedDate = plannedDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _openAddExercise(
        recommendation: selectedRecommendation,
        initialDate: selectedDate,
      );
    });
  }

  void _loadExercises() {
    _exercisesFuture = _repository.getExerciseLogs();
  }

  Future<void> _refreshExercises() async {
    setState(_loadExercises);

    try {
      await _exercisesFuture;
    } catch (_) {
      // The FutureBuilder displays the error message.
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _showError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to complete this action. Please try again.'),
      ),
    );
  }

  Future<void> _openAddExercise({
    ExerciseRecommendationModel? recommendation,
    DateTime? initialDate,
  }) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExercisePage(
          initialExerciseName: recommendation?.name,
          initialExerciseType: recommendation?.type,
          initialDurationMinutes: recommendation?.durationMinutes,
          initialIsCompleted: recommendation == null ? null : false,
          initialDate: initialDate,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _refreshExercises();
    }
  }

  Future<void> _markCompleted(ExerciseLogModel exercise) async {
    final today = DateTime.now();

    final exerciseDay = DateTime(
      exercise.performedAt.year,
      exercise.performedAt.month,
      exercise.performedAt.day,
    );

    final currentDay = DateTime(today.year, today.month, today.day);

    if (exerciseDay.isAfter(currentDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A future exercise cannot be marked as completed.'),
        ),
      );
      return;
    }

    try {
      await _repository.updateExercise(exercise.copyWith(isCompleted: true));

      await _refreshExercises();
    } catch (_) {
      _showError();
    }
  }

  Future<void> _deleteExercise(ExerciseLogModel exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Exercise?'),
          content: Text(
            'Delete "${exercise.exerciseName}" '
            'from your exercise history?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteExercise(exercise.id);
      await _refreshExercises();
    } catch (_) {
      _showError();
    }
  }

  Widget _exerciseCard(ExerciseLogModel exercise) {
    final completed = exercise.isCompleted;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.check_circle : Icons.schedule,
                  color: completed ? const Color(0xFF16876E) : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete exercise',
                  onPressed: () => _deleteExercise(exercise),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: ${exercise.exerciseType}'),
            const SizedBox(height: 4),
            Text('Duration: ${exercise.durationMinutes} minutes'),
            const SizedBox(height: 4),
            Text('Date: ${_formatDate(exercise.performedAt)}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  label: Text(completed ? 'Completed' : 'Planned'),
                  backgroundColor: completed
                      ? const Color(0xFFE0F4ED)
                      : const Color(0xFFFFF1DA),
                ),
                const Spacer(),
                if (!completed)
                  TextButton.icon(
                    onPressed: () => _markCompleted(exercise),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Completed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Exercise History'),
        backgroundColor: const Color(0xFFF5FAFC),
        foregroundColor: const Color(0xFF086F67),
        actions: [
          IconButton(
            tooltip: 'Refresh exercises',
            onPressed: _refreshExercises,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
      body: FutureBuilder<List<ExerciseLogModel>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load exercise history.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshExercises,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final exercises = snapshot.data ?? <ExerciseLogModel>[];

          if (exercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Color(0xFF16876E),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No exercises recorded yet.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap Add Exercise to record '
                      'your first activity.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openAddExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshExercises,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return _exerciseCard(exercises[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
