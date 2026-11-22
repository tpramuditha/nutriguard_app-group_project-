import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/repositories/food_log_repository.dart';
import 'meal_suggestion_card.dart';

class TodayMealsCard extends StatefulWidget {
  const TodayMealsCard({super.key});

  @override
  State<TodayMealsCard> createState() => _TodayMealsCardState();
}

class _TodayMealsCardState extends State<TodayMealsCard> {
  final FoodLogRepository _repository = FoodLogRepository();

  late Future<List<FoodLogModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadFoodLogs();
  }

  Future<List<FoodLogModel>> _loadFoodLogs() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future<List<FoodLogModel>>.error(
        StateError('Please log in to view your meals.'),
      );
    }

    return _repository.getFoodLogs(userId: user.uid);
  }

  void _refreshMeals() {
    setState(() {
      _logsFuture = _loadFoodLogs();
    });
  }

  Future<void> _openFoodHistory() async {
    await Navigator.pushNamed(context, RouteNames.foodHistory);

    if (!mounted) return;

    _refreshMeals();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();

    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  List<FoodLogModel> _todaysLogs(List<FoodLogModel> allLogs) {
    return allLogs.where((log) {
      return _isToday(log.loggedAt);
    }).toList();
  }

  String _imagePathForMeal(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return 'assets/images/dashboard/breakfast.png';
      case 'Lunch':
        return 'assets/images/dashboard/lunch.png';
      case 'Snack':
        return 'assets/images/dashboard/snack.png';
      default:
        return 'assets/images/dashboard/dinner.png';
    }
  }

  Widget _buildMealsContent() {
    return FutureBuilder<List<FoodLogModel>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              const Text(
                'Unable to load today\'s meals.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _refreshMeals,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          );
        }

        final todaysLogs = _todaysLogs(snapshot.data ?? []);

        if (todaysLogs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.no_meals_outlined,
                  color: AppColors.primary,
                  size: 44,
                ),
                SizedBox(height: 12),
                Text(
                  'No meals logged today.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (final log in todaysLogs) ...[
              _mealItem(
                context,
                title: log.mealType,
                description:
                    '${log.foodName} '
                    '(${log.grams.toStringAsFixed(0)} g)',
                calories: log.calories.round(),
                imagePath: _imagePathForMeal(log.mealType),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Today's Meals",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh meals',
                onPressed: _refreshMeals,
                icon: const Icon(Icons.refresh),
              ),
              TextButton(
                onPressed: _openFoodHistory,
                child: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildMealsContent(),

          const SizedBox(height: 20),

          // Keep the existing AI suggestion banner.
          const MealSuggestionCard(),
        ],
      ),
    );
  }

  Widget _mealItem(
    BuildContext context, {
    required String title,
    required String description,
    required int calories,
    required String imagePath,
  }) {
    return Material(
      color: const Color(0xFFF9FCFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openFoodHistory,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 68,
                      height: 68,
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '$calories kcal',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
