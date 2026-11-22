import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../nutrition/data/repositories/nutrition_goal_repository.dart';
import '../../../nutrition/data/models/nutrition_goal_model.dart';

class PersonalGoalsCard extends StatefulWidget {
  const PersonalGoalsCard({super.key});

  @override
  State<PersonalGoalsCard> createState() => _PersonalGoalsCardState();
}

class _PersonalGoalsCardState extends State<PersonalGoalsCard> {
  String _selectedGoal = 'Weight Loss';
  int _calorieTarget = 2000;

  final NutritionGoalRepository _nutritionGoalRepository =
      NutritionGoalRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNutritionGoal();
  }

  Future<void> _loadNutritionGoal() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final goal = await _nutritionGoalRepository.getNutritionGoal(
        userId: user.uid,
      );

      if (!mounted) return;

      setState(() {
        _calorieTarget = goal.dailyCalorieTarget;
        _selectedGoal = goal.goalType;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load nutrition goals.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNutritionGoal({
    required int calorieTarget,
    required String goalType,
  }) async {
    if (_isSaving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your nutrition goals.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _nutritionGoalRepository.saveNutritionGoal(
        userId: user.uid,
        goal: NutritionGoalModel(
          dailyCalorieTarget: calorieTarget,
          goalType: goalType,
        ),
      );

      if (!mounted) return;

      setState(() {
        _calorieTarget = calorieTarget;
        _selectedGoal = goalType;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nutrition goals saved successfully!')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save nutrition goals. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editCalorieTarget() async {
    String enteredValue = _calorieTarget.toString();

    final newTarget = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Daily Calorie Target'),
          content: TextFormField(
            initialValue: enteredValue,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Calories (kcal)',
              hintText: 'e.g. 2000',
            ),
            onChanged: (value) {
              enteredValue = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(enteredValue.trim());

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid calorie target'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (newTarget != null) {
      await _saveNutritionGoal(
        calorieTarget: newTarget,
        goalType: _selectedGoal,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Personal Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              const Expanded(child: Text('Goal')),
              DropdownButton<String>(
                value: _selectedGoal,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Weight Loss',
                    child: Text('Weight Loss'),
                  ),
                  DropdownMenuItem(
                    value: 'Maintain Weight',
                    child: Text('Maintain Weight'),
                  ),
                  DropdownMenuItem(
                    value: 'Weight Gain',
                    child: Text('Weight Gain'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) async {
                        if (value != null && value != _selectedGoal) {
                          await _saveNutritionGoal(
                            calorieTarget: _calorieTarget,
                            goalType: value,
                          );
                        }
                      },
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text('Daily Calorie Target')),
              Text(
                '$_calorieTarget kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              IconButton(
                onPressed: _isSaving ? null : _editCalorieTarget,
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
