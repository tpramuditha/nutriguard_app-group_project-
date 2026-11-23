import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/food_log_model.dart';
import '../../data/repositories/food_log_repository.dart';

class RecentlyLoggedFoods extends StatefulWidget {
  final ValueChanged<FoodLogModel> onFoodSelected;

  const RecentlyLoggedFoods({super.key, required this.onFoodSelected});

  @override
  State<RecentlyLoggedFoods> createState() => _RecentlyLoggedFoodsState();
}

class _RecentlyLoggedFoodsState extends State<RecentlyLoggedFoods> {
  final FoodLogRepository _repository = FoodLogRepository();

  late Future<List<FoodLogModel>> _recentFoodsFuture;

  @override
  void initState() {
    super.initState();
    _recentFoodsFuture = _loadRecentFoods();
  }

  Future<List<FoodLogModel>> _loadRecentFoods() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('Please log in to view recent foods.');
    }

    final logs = await _repository.getFoodLogs(userId: user.uid);

    // Repository already sorts food logs newest first.
    // Display only the four most recent entries.
    return logs.take(4).toList();
  }

  void _refresh() {
    setState(() {
      _recentFoodsFuture = _loadRecentFoods();
    });
  }

  Widget _foodCard(FoodLogModel food) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onFoodSelected(food),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0ECE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFE0F2EC),
              child: Icon(Icons.restaurant, color: AppColors.primary),
            ),

            const SizedBox(height: 10),

            Text(
              food.foodName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${food.grams.toStringAsFixed(0)} g',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              food.mealType,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${food.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodLogModel>>(
      future: _recentFoodsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              const Text('Unable to load recent foods.'),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          );
        }

        final foods = snapshot.data ?? [];

        if (foods.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Your recently logged foods will appear here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          );
        }

        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _foodCard(foods[index]);
            },
          ),
        );
      },
    );
  }
}
