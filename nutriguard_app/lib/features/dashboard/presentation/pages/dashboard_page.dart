import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../profile/presentation/widgets/logout_dialog.dart';
import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/repositories/food_log_repository.dart';
import '../../../nutrition/data/models/nutrition_goal_model.dart';
import '../../../nutrition/data/repositories/nutrition_goal_repository.dart';

import '../widgets/macro_chart.dart';
import '../widgets/quick_actions.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/calorie_progress_card.dart';
import '../widgets/today_meals_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FoodLogRepository _foodLogRepository = FoodLogRepository();

  final NutritionGoalRepository _nutritionGoalRepository =
      NutritionGoalRepository();

  late Future<NutritionGoalModel> _nutritionGoalFuture;

  bool _isLoggingOut = false;

  late Future<List<FoodLogModel>> _todaysFoodLogsFuture;
  int _mealsRefreshVersion = 0;

  Future<NutritionGoalModel> _loadNutritionGoal() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in to view your nutrition goal.');
    }

    return _nutritionGoalRepository.getNutritionGoal(userId: user.uid);
  }

  @override
  void initState() {
    super.initState();

    _todaysFoodLogsFuture = _loadTodaysFoodLogs();
    _nutritionGoalFuture = _loadNutritionGoal();
  }

  Future<List<FoodLogModel>> _loadTodaysFoodLogs() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in to view your nutrition.');
    }

    final logs = await _foodLogRepository.getFoodLogs(userId: user.uid);

    final now = DateTime.now();

    return logs.where((log) {
      final date = log.loggedAt.toLocal();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  void _refreshDashboard() {
    if (!mounted) return;

    setState(() {
      _todaysFoodLogsFuture = _loadTodaysFoodLogs();
      _nutritionGoalFuture = _loadNutritionGoal();
      _mealsRefreshVersion++;
    });
  }

  Future<void> _openScanner() async {
    await Navigator.pushNamed(context, RouteNames.foodScanner);

    if (!mounted) return;

    _refreshDashboard();
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    // Index 0 = Home
    if (index == 0) {
      return;
    }

    // Index 1 = Food Scanner
    if (index == 1) {
      _openScanner();
      return;
    }

    // Index 2 = Meal Planner
    if (index == 2) {
      Navigator.pushNamed(context, RouteNames.planner);
      return;
    }

    // Index 3 = Progress
    if (index == 3) {
      Navigator.pushNamed(context, RouteNames.progress);
      return;
    }

    // Index 4 = Profile
    if (index == 4) {
      Navigator.pushNamed(context, RouteNames.profile);
      return;
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const LogoutDialog(),
    );

    if (!mounted) return;

    if (shouldLogout == true) {
      await _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'NutriGuard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,

        actions: [
          PopupMenuButton<String>(
            enabled: !_isLoggingOut,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Log Out')),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with Firebase username.
            const DashboardHeader(),

            const SizedBox(height: 24),

            FutureBuilder<List<FoodLogModel>>(
              future: _todaysFoodLogsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Unable to load daily nutrition.'),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _refreshDashboard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final logs = snapshot.data ?? <FoodLogModel>[];

                final totalCalories = logs.fold<double>(
                  0,
                  (sum, log) => sum + log.calories,
                );

                final totalProtein = logs.fold<double>(
                  0,
                  (sum, log) => sum + log.protein,
                );

                final totalCarbs = logs.fold<double>(
                  0,
                  (sum, log) => sum + log.carbs,
                );

                final totalFat = logs.fold<double>(
                  0,
                  (sum, log) => sum + log.fat,
                );

                return Column(
                  children: [
                    FutureBuilder<NutritionGoalModel>(
                      future: _nutritionGoalFuture,
                      builder: (context, goalSnapshot) {
                        if (goalSnapshot.connectionState !=
                            ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (goalSnapshot.hasError || !goalSnapshot.hasData) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    'Unable to load your calorie target.',
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _refreshDashboard,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final goal = goalSnapshot.data!;

                        return CalorieProgressCard(
                          consumedCalories: totalCalories.round(),
                          targetCalories: goal.dailyCalorieTarget,
                          burnedCalories: 0,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    MacroChart(
                      consumedProtein: totalProtein,
                      consumedCarbs: totalCarbs,
                      consumedFat: totalFat,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Existing Quick Actions.
            QuickActions(onScanFood: _openScanner),

            const SizedBox(height: 24),

            // Today's Meals.
            TodayMealsCard(key: ValueKey(_mealsRefreshVersion)),

            const SizedBox(height: 24),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
