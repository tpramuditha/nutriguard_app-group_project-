import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

import '../../data/models/exercise_recommendation_model.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import '../../domain/services/weekly_exercise_schedule_service.dart';
import '../../data/models/saved_weekly_exercise_plan.dart';
import '../../data/repositories/weekly_exercise_plan_repository.dart';
import '../../../exercise/data/models/exercise_log_model.dart';
import '../../../exercise/data/repositories/exercise_log_repository.dart';
import '../../domain/services/exercise_plan_date_service.dart';
import '../../domain/services/weekly_exercise_completion_service.dart';

import '../widgets/exercise_swap_action.dart';
import '../widgets/exercise_start_action.dart';

class ExerciseRecommendationPage extends StatefulWidget {
  final Future<SavedWeeklyExercisePlan?> Function(DateTime referenceDate)?
  planLoader;

  const ExerciseRecommendationPage({super.key, this.planLoader});

  @override
  State<ExerciseRecommendationPage> createState() =>
      _ExerciseRecommendationPageState();
}

class _ExerciseRecommendationPageState
    extends State<ExerciseRecommendationPage> {
  static const Color _primary = Color(0xFF086F67);
  static const Color _background = Color(0xFFF5FAFC);

  final ExerciseRecommendationService _service =
      const ExerciseRecommendationService();

  final WeeklyExerciseScheduleService _weeklyService =
      const WeeklyExerciseScheduleService();

  FitnessGoal _selectedGoal = FitnessGoal.generalFitness;
  ActivityLevel _selectedLevel = ActivityLevel.beginner;
  ExercisePreference _selectedPreference = ExercisePreference.any;

  int _selectedDay = DateTime.now().weekday - 1;

  List<ExerciseRecommendationModel> _recommendations = [];
  bool _hasGenerated = false;

  WeeklyExerciseSchedule? _weeklySchedule;

  late final WeeklyExercisePlanRepository _planRepository =
      WeeklyExercisePlanRepository();

  bool _isSavingPlan = false;

  bool _isLoadingPlan = false;

  late final ExerciseLogRepository _exerciseLogRepository =
      ExerciseLogRepository();

  final WeeklyExerciseCompletionService _completionService =
      const WeeklyExerciseCompletionService();

  List<ExerciseLogModel> _exerciseLogs = [];

  bool _isLoadingExerciseProgress = false;
  bool _exerciseProgressLoaded = false;
  bool _exerciseProgressError = false;
  int _planRevision = 0;

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _goalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.generalFitness:
        return 'General Fitness';
      case FitnessGoal.buildConsistency:
        return 'Build Consistency';
      case FitnessGoal.improveEndurance:
        return 'Improve Endurance';
      case FitnessGoal.buildStrength:
        return 'Build Strength';
    }
  }

  String _preferenceLabel(ExercisePreference preference) {
    switch (preference) {
      case ExercisePreference.any:
        return 'Any Exercise';
      case ExercisePreference.cardio:
        return 'Cardio';
      case ExercisePreference.strength:
        return 'Strength';
      case ExercisePreference.flexibility:
        return 'Flexibility';
    }
  }

  IconData _exerciseIcon(String type) {
    switch (type) {
      case 'Cardio':
        return Icons.directions_walk;
      case 'Strength':
        return Icons.fitness_center;
      case 'Flexibility':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }

  ExerciseRecommendationRequest _createRequest() {
    return ExerciseRecommendationRequest(
      goal: _selectedGoal,
      activityLevel: _selectedLevel,
      preference: _selectedPreference,
    );
  }

  void _generateRecommendations() {
    final results = _service.recommend(
      request: _createRequest(),
      maxResults: 3,
    );

    setState(() {
      _recommendations = results;
      _hasGenerated = true;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSavedWeeklyPlan();
      }
    });
  }

  Future<void> _loadSavedWeeklyPlan() async {
    if (_isLoadingPlan) return;

    if (widget.planLoader == null) {
      if (Firebase.apps.isEmpty) return;

      if (FirebaseAuth.instance.currentUser == null) {
        return;
      }
    }

    final currentRevision = _planRevision;

    setState(() {
      _isLoadingPlan = true;
    });

    try {
      final savedPlan = widget.planLoader != null
          ? await widget.planLoader!(DateTime.now())
          : await _planRepository.loadPlan(referenceDate: DateTime.now());

      if (!mounted || currentRevision != _planRevision) {
        return;
      }

      if (savedPlan == null) {
        return;
      }

      setState(() {
        _selectedGoal = savedPlan.request.goal;
        _selectedLevel = savedPlan.request.activityLevel;
        _selectedPreference = savedPlan.request.preference;

        _weeklySchedule = savedPlan.schedule;

        // These suggestions can be regenerated separately.
        _recommendations = [];
        _hasGenerated = false;
      });

      await _loadExerciseProgress();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to restore saved weekly plan. '
            'You can generate a new plan.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlan = false;
        });
      }
    }
  }

  void _generateWeeklySchedule() {
    final schedule = _weeklyService.generate(request: _createRequest());

    _planRevision++;

    setState(() {
      _weeklySchedule = schedule;
      _exerciseLogs = [];
      _exerciseProgressLoaded = false;
      _exerciseProgressError = false;
    });

    unawaited(_loadExerciseProgress());
  }

  Future<void> _loadExerciseProgress() async {
    if (_weeklySchedule == null) return;

    // Avoid accessing Firebase in UI-only widget tests.
    if (Firebase.apps.isEmpty) return;

    if (FirebaseAuth.instance.currentUser == null) return;

    if (_isLoadingExerciseProgress) return;

    final currentRevision = _planRevision;

    setState(() {
      _isLoadingExerciseProgress = true;
      _exerciseProgressError = false;
    });

    try {
      final logs = await _exerciseLogRepository.getExerciseLogs();

      if (!mounted || currentRevision != _planRevision) {
        return;
      }

      setState(() {
        _exerciseLogs = logs;
        _exerciseProgressLoaded = true;
      });
    } catch (_) {
      if (!mounted || currentRevision != _planRevision) {
        return;
      }

      setState(() {
        _exerciseProgressLoaded = false;
        _exerciseProgressError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExerciseProgress = false;
        });
      }
    }
  }

  Future<void> _saveWeeklyPlan() async {
    if (_isSavingPlan) return;

    final schedule = _weeklySchedule;

    if (schedule == null) {
      return;
    }

    final plan = SavedWeeklyExercisePlan.fromSchedule(
      referenceDate: DateTime.now(),
      request: _createRequest(),
      schedule: schedule,
    );

    setState(() {
      _isSavingPlan = true;
    });

    try {
      await _planRepository.savePlan(plan);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly exercise plan saved successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save weekly plan. '
            'Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPlan = false;
        });
      }
    }
  }

  void _preferencesChanged() {
    _planRevision++;

    setState(() {
      _hasGenerated = false;
      _recommendations = [];
      _weeklySchedule = null;
      _exerciseLogs = [];
      _exerciseProgressLoaded = false;
      _exerciseProgressError = false;
    });

    unawaited(_loadExerciseProgress());
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityLevelSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4F0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: ActivityLevel.values.map((level) {
          final selected = _selectedLevel == level;

          final label = level == ActivityLevel.beginner
              ? 'Beginner'
              : 'Intermediate';

          return Expanded(
            child: InkWell(
              key: ValueKey('level-${level.name}'),
              onTap: () {
                if (_selectedLevel == level) return;

                setState(() {
                  _selectedLevel = level;
                });

                _preferencesChanged();
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? Colors.white : _primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _preferencesCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeading('Your Preferences', Icons.tune),
            const SizedBox(height: 20),

            DropdownButtonFormField<FitnessGoal>(
              key: ValueKey(_selectedGoal),
              initialValue: _selectedGoal,
              decoration: const InputDecoration(
                labelText: 'Fitness Goal',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
              items: FitnessGoal.values.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(_goalLabel(goal)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedGoal = value;
                });

                _preferencesChanged();
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Activity Level',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
            const SizedBox(height: 10),

            _activityLevelSelector(),

            const SizedBox(height: 20),

            DropdownButtonFormField<ExercisePreference>(
              key: ValueKey(_selectedPreference),
              initialValue: _selectedPreference,
              decoration: const InputDecoration(
                labelText: 'Preferred Exercise Type',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: ExercisePreference.values.map((preference) {
                return DropdownMenuItem(
                  value: preference,
                  child: Text(_preferenceLabel(preference)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedPreference = value;
                });

                _preferencesChanged();
              },
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateRecommendations,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get Recommendations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('Weekly Exercise Plan', Icons.calendar_month_outlined),

        const SizedBox(height: 6),

        const Text(
          'Choose a day to view its exercise plan.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),

        const SizedBox(height: 14),

        Row(
          children: List.generate(7, (index) {
            final selected = index == _selectedDay;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  key: ValueKey('exercise-day-$index'),
                  onTap: () {
                    setState(() {
                      _selectedDay = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _primary : const Color(0xFFDDEBE8),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : _primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'Selected day: ${_dayNames[_selectedDay]}',
            style: const TextStyle(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _weeklySummaryTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyCompletionSection(WeeklyExerciseSchedule schedule) {
    const dateService = ExercisePlanDateService();

    final weekStart = dateService.dateForWeekday(
      referenceDate: DateTime.now(),
      weekday: DateTime.monday,
    );

    final completed = _completionService.completedSessions(
      schedule: schedule,
      weekStart: weekStart,
      exerciseLogs: _exerciseLogs,
    );

    final remaining = _completionService.remainingSessions(
      schedule: schedule,
      weekStart: weekStart,
      exerciseLogs: _exerciseLogs,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingExerciseProgress) const LinearProgressIndicator(),

        if (_exerciseProgressLoaded) ...[
          Row(
            children: [
              _weeklySummaryTile(
                title: 'Completed Sessions',
                value: '$completed',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _weeklySummaryTile(
                title: 'Remaining Sessions',
                value: '$remaining',
                icon: Icons.pending_actions_outlined,
              ),
            ],
          ),
        ] else if (_exerciseProgressError)
          const Text(
            'Unable to load exercise progress.',
            textAlign: TextAlign.center,
          )
        else
          const Text(
            'Exercise progress has not been loaded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          key: const ValueKey('refresh-exercise-progress'),
          onPressed: _isLoadingExerciseProgress ? null : _loadExerciseProgress,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Exercise Progress'),
        ),
      ],
    );
  }

  Widget _weeklyScheduleSection() {
    final schedule = _weeklySchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingPlan) ...[
          const LinearProgressIndicator(color: Color(0xFF086F67)),
          const SizedBox(height: 12),
          const Text(
            'Restoring saved weekly plan...',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _generateWeeklySchedule,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              schedule == null
                  ? 'Generate Week Schedule'
                  : 'Regenerate Week Schedule',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        if (schedule == null) ...[
          const SizedBox(height: 12),
          const Text(
            'Generate a sample weekly plan using '
            'your selected fitness preferences.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ] else ...[
          const SizedBox(height: 18),

          Row(
            children: [
              _weeklySummaryTile(
                title: 'Planned Sessions',
                value: '${schedule.plannedSessions}',
                icon: Icons.fitness_center,
              ),
              const SizedBox(width: 10),
              _weeklySummaryTile(
                title: 'Planned Minutes',
                value: '${schedule.plannedMinutes}',
                icon: Icons.timer_outlined,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _weeklyCompletionSection(schedule),

          const SizedBox(height: 20),

          _selectedDayPlan(schedule.forWeekday(_selectedDay + 1)),

          const SizedBox(height: 16),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: const ValueKey('save-weekly-plan'),
              onPressed: _isSavingPlan ? null : _saveWeeklyPlan,
              icon: _isSavingPlan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isSavingPlan ? 'Saving Weekly Plan...' : 'Save Weekly Plan',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF086F67),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'This is a sample activity schedule, '
            'not a medically prescribed workout plan. '
            'Adjust activity and rest to your needs.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _selectedDayPlan(DailyExercisePlan day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('${day.dayName} Plan', Icons.event_available_outlined),
        const SizedBox(height: 12),

        if (day.isRestDay)
          Card(
            color: const Color(0xFFEAF6F2),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.spa_outlined, size: 38, color: _primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Rest Day',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${day.dayName} is a recovery day '
                    'in this sample schedule.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Existing exercise recommendation card
              _recommendationCard(day.exercise!),

              const SizedBox(height: 8),

              // Existing Swap Exercise button
              ExerciseSwapAction(
                schedule: _weeklySchedule!,
                weekday: day.weekday,
                request: _createRequest(),
                onSwapped: (updatedSchedule) {
                  _planRevision++;

                  setState(() {
                    _weeklySchedule = updatedSchedule;
                  });
                },
              ),

              // NEW: Space between the two buttons
              const SizedBox(height: 12),

              // NEW: Start Session button
              ExerciseStartAction(
                exercise: day.exercise!,
                weekday: day.weekday,
              ),
            ],
          ),
      ],
    );
  }

  Widget _informationList({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _recommendationCard(ExerciseRecommendationModel exercise) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F4ED),
                  child: Icon(_exerciseIcon(exercise.type), color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text('${exercise.durationMinutes} min'),
                ),
                Chip(
                  avatar: const Icon(Icons.speed, size: 18),
                  label: Text('${exercise.intensity} Intensity'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              exercise.description,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),

            if (exercise.benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              _informationList(
                title: 'Benefits',
                items: exercise.benefits,
                icon: Icons.check_circle_outline,
                color: _primary,
              ),
            ],

            if (exercise.safetyNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _informationList(
                title: 'Safety Notes',
                items: exercise.safetyNotes,
                icon: Icons.info_outline,
                color: Colors.orange.shade800,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultsSection() {
    if (!_hasGenerated) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 42,
              color: Color(0xFF268C82),
            ),
            SizedBox(height: 12),
            Text(
              'Choose your preferences and tap '
              'Get Recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No recommendations available for '
          'these preferences.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('Recommended Exercises', Icons.recommend_outlined),

        const SizedBox(height: 8),

        Text(
          '${_recommendations.length} suggestions '
          'based on your selected preferences',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),

        const SizedBox(height: 14),

        ..._recommendations.map(_recommendationCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Exercise Recommendations'),
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              const Text(
                'Find activities that match your '
                'goals and preferences.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              _preferencesCard(),

              const SizedBox(height: 22),

              _daySelector(),

              const SizedBox(height: 16),

              // New: weekly schedule generation.
              _weeklyScheduleSection(),

              const SizedBox(height: 22),

              // Existing recommendations remain available.
              _resultsSection(),

              const SizedBox(height: 18),

              const Card(
                color: Color(0xFFFFF8E8),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These suggestions are based '
                          'on selected preferences only. '
                          'They do not assess whether an '
                          'exercise is medically safe for '
                          'you. If you have health concerns '
                          'or symptoms, seek appropriate '
                          'professional advice before '
                          'starting or increasing activity.',
                          style: TextStyle(fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
