import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/route_names.dart';
import '../../data/repositories/progress_data_repository.dart';
import '../../domain/services/progress_calculation_service.dart';

import '../widgets/calorie_intake_chart.dart';
import '../widgets/macro_trends_chart.dart';
import '../widgets/health_marker_trends_section.dart';
import '../widgets/exercise_completion_section.dart';
import '../widgets/weight_trend_section.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final ProgressDataRepository _repository = ProgressDataRepository();

  final ProgressCalculationService _calculationService =
      const ProgressCalculationService();

  Future<ProgressDataSnapshot>? _progressFuture;

  String _selectedPeriod = 'Week';
  String? _loadedUserId;

  int _exerciseRefreshVersion = 0;
  int _weightRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    _loadedUserId = userId;

    _progressFuture = userId == null
        ? null
        : _repository.loadProgressData(userId: userId);
  }

  Future<void> _refreshProgress() async {
    setState(_loadProgress);

    try {
      await _progressFuture;
    } catch (_) {
      // The FutureBuilder displays loading errors.
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _periodStart(DateTime today) {
    final date = _dateOnly(today);

    switch (_selectedPeriod) {
      case 'Week':
        return date.subtract(Duration(days: date.weekday - 1));

      case 'Month':
        return DateTime(date.year, date.month, 1);

      case '6 Months':
        return DateTime(date.year, date.month - 5, 1);

      default:
        return date;
    }
  }

  Widget _periodSelector() {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'Week', label: Text('Week')),
        ButtonSegment(value: 'Month', label: Text('Month')),
        ButtonSegment(value: '6 Months', label: Text('6 Months')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (selection) {
        setState(() {
          _selectedPeriod = selection.first;
        });
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color color = AppColors.primary,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _macroTile({
    required String title,
    required double grams,
    required IconData icon,
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2EC),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        trailing: Text(
          '${grams.toStringAsFixed(1)} g',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _goalAdherenceCard(GoalAdherenceResult result) {
    final hasData = result.loggedDays > 0;

    return Card(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.track_changes, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Goal Adherence',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              hasData
                  ? '${result.percentage.toStringAsFixed(1)}%'
                  : 'No data yet',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: hasData ? (result.percentage / 100).clamp(0.0, 1.0) : 0.0,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: const Color(0xFFE2ECE8),
              color: AppColors.primary,
            ),

            const SizedBox(height: 12),

            Text(
              hasData
                  ? '${result.daysWithinTarget} of '
                        '${result.loggedDays} logged days '
                        'within the calorie target range.'
                  : 'Start logging your meals to track '
                        'your calorie goal adherence.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),

            if (hasData) ...[
              const SizedBox(height: 8),
              const Text(
                'Target range: within 10% above or below '
                'your daily calorie goal.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 8),

            const Text(
              'Calculated from logged food only. '
              'This does not confirm complete intake '
              'or medical goal achievement.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressContent(ProgressDataSnapshot snapshot) {
    final today = _dateOnly(DateTime.now());
    final startDate = _periodStart(today);

    final summaries = _calculationService.calculateDateRange(
      startDate: startDate,
      endDate: today,
      foodLogs: snapshot.foodLogs,
    );

    final loggedDays = summaries.where((day) => day.mealCount > 0).length;

    final totalCalories = summaries.fold<double>(
      0,
      (sum, day) => sum + day.calories,
    );

    final totalProtein = summaries.fold<double>(
      0,
      (sum, day) => sum + day.protein,
    );

    final totalCarbs = summaries.fold<double>(0, (sum, day) => sum + day.carbs);

    final totalFat = summaries.fold<double>(0, (sum, day) => sum + day.fat);

    final averageCalories = _calculationService.calculateAverageCalories(
      summaries,
    );

    final streak = _calculationService.calculateLoggingStreak(
      foodLogs: snapshot.foodLogs,
      today: today,
    );

    final dailyGoal = snapshot.nutritionGoal.dailyCalorieTarget;

    final todaySummary = _calculationService.calculateDailySummary(
      date: today,
      foodLogs: snapshot.foodLogs,
    );

    final goalPercentage = todaySummary.calorieGoalPercentage(dailyGoal);

    final goalAdherence = _calculationService.calculateGoalAdherence(
      summaries: summaries,
      dailyCalorieTarget: dailyGoal,
    );

    return RefreshIndicator(
      onRefresh: _refreshProgress,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _periodSelector(),

          const SizedBox(height: 12),

          Text(
            '${startDate.year}-'
            '${startDate.month.toString().padLeft(2, '0')}-'
            '${startDate.day.toString().padLeft(2, '0')}'
            ' to '
            '${today.year}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),

          _sectionTitle('Nutrition Overview'),

          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'Average Calories',
                  value: averageCalories.toStringAsFixed(0),
                  subtitle: 'kcal per calendar day',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
              Expanded(
                child: _summaryCard(
                  title: 'Logging Streak',
                  value: '$streak days',
                  subtitle: 'Consecutive logged days',
                  icon: Icons.bolt_outlined,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'Total Calories',
                  value: totalCalories.toStringAsFixed(0),
                  subtitle: 'kcal in selected period',
                  icon: Icons.restaurant_outlined,
                ),
              ),
              Expanded(
                child: _summaryCard(
                  title: 'Days Logged',
                  value: '$loggedDays',
                  subtitle: 'of ${summaries.length} days',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _goalAdherenceCard(goalAdherence),

          const SizedBox(height: 12),

          CalorieIntakeChart(
            summaries: summaries,
            dailyCalorieTarget: dailyGoal,
          ),

          const SizedBox(height: 12),

          MacroTrendsChart(summaries: summaries),

          const SizedBox(height: 12),

          _sectionTitle('Today\'s Calorie Goal'),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${todaySummary.calories.toStringAsFixed(0)}'
                    ' / $dailyGoal kcal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (goalPercentage / 100).clamp(0.0, 1.0),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: const Color(0xFFE2ECE8),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${goalPercentage.toStringAsFixed(1)}%'
                    ' of daily calorie target',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Based on logged food only.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle('Macronutrient Intake'),

          _macroTile(
            title: 'Protein',
            grams: totalProtein,
            icon: Icons.fitness_center_outlined,
          ),

          _macroTile(
            title: 'Carbohydrates',
            grams: totalCarbs,
            icon: Icons.grain_outlined,
          ),

          _macroTile(
            title: 'Fat',
            grams: totalFat,
            icon: Icons.opacity_outlined,
          ),

          const SizedBox(height: 16),

          HealthMarkerTrendsSection(startDate: startDate, endDate: today),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Exercise completion statistics for the selected period.
          ExerciseCompletionSection(
            key: ValueKey('exercise-completion-$_exerciseRefreshVersion'),
            startDate: startDate,
            endDate: today,
          ),

          const SizedBox(height: 16),

          // Exercise tracking navigation.
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fitness_center, color: Color(0xFF086F67)),
                      SizedBox(width: 10),
                      Text(
                        'Exercise Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF086F67),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Record your activities, manage planned '
                    'exercises, and track completed workouts.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, RouteNames.exercise);

                        if (!mounted) return;

                        // Reload exercise statistics when returning
                        // from Exercise History.
                        setState(() {
                          _exerciseRefreshVersion++;
                        });
                      },

                      icon: const Icon(Icons.history),
                      label: const Text('View Exercise History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF086F67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Weight trend for the selected period.
          WeightTrendSection(
            key: ValueKey('weight-trend-$_weightRefreshVersion'),
            startDate: startDate,
            endDate: today,
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        color: Color(0xFF086F67),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Weight History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF086F67),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Record your weight and review previous '
                    'measurements to monitor changes over time.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          RouteNames.weightHistory,
                        );

                        if (!mounted) return;

                        // Reload weight measurements after returning
                        // from Weight History.
                        setState(() {
                          _weightRefreshVersion++;
                        });
                      },

                      icon: const Icon(Icons.history),
                      label: const Text('View Weight History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF086F67),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (snapshot.foodLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No food logs yet. Start logging meals '
                  'to see your nutrition progress.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != _loadedUserId) {
      _loadProgress();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
        actions: [
          IconButton(
            tooltip: 'Refresh progress',
            onPressed: _refreshProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your progress.'))
          : FutureBuilder<ProgressDataSnapshot>(
              future: _progressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load progress data.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshProgress,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No progress data available.'),
                  );
                }

                return _progressContent(snapshot.data!);
              },
            ),
    );
  }
}
