import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:math';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/food_log_model.dart';
import '../../data/repositories/food_log_repository.dart';

class ManualFoodEntryPage extends StatefulWidget {
  final String? initialFoodName;
  final FoodLogRepository? foodLogRepository;
  final FirebaseAuth? firebaseAuth;

  const ManualFoodEntryPage({
    super.key,
    this.initialFoodName,
    this.foodLogRepository,
    this.firebaseAuth,
  });

  @override
  State<ManualFoodEntryPage> createState() => _ManualFoodEntryPageState();
}

class _ManualFoodEntryPageState extends State<ManualFoodEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final FoodLogRepository _foodLogRepository;
  late final FirebaseAuth _firebaseAuth;

  bool _isSaving = false;

  bool _hasAttemptedSave = false;

  late final String _submissionId =
      'manual-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  late final DateTime _submissionLoggedAt = DateTime.now();

  final _nameController = TextEditingController();
  final _gramsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _mealType = 'Breakfast';

  @override
  void initState() {
    super.initState();

    _foodLogRepository = widget.foodLogRepository ?? FoodLogRepository();

    _firebaseAuth = widget.firebaseAuth ?? FirebaseAuth.instance;

    final initialName = widget.initialFoodName?.trim();

    if (initialName != null && initialName.isNotEmpty) {
      _nameController.text = initialName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  String? _validateNutrition(String? value) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null || !number.isFinite) {
      return 'Enter a valid number';
    }

    if (number < 0 || number > 1000000) {
      return 'Enter a value between 0 and 1000000';
    }

    return null;
  }

  String? _validateGrams(String? value) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null || !number.isFinite) {
      return 'Enter a valid portion';
    }

    if (number <= 0 || number > 5000) {
      return 'Portion must be between 0 and 5000 g';
    }

    return null;
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    String unit, {
    bool isGrams = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
      validator: isGrams ? _validateGrams : _validateNutrition,
    );
  }

  Future<bool> _confirmSuspiciousNutrition() async {
    final calories = double.parse(_caloriesController.text.trim());
    final protein = double.parse(_proteinController.text.trim());
    final carbs = double.parse(_carbsController.text.trim());
    final fat = double.parse(_fatController.text.trim());

    final warnings = <String>[];

    if (calories == 0) {
      warnings.add('Calories are entered as 0 kcal.');
    }

    if (protein == 0 && carbs == 0 && fat == 0) {
      warnings.add('Protein, carbohydrates and fat are all 0 g.');
    }

    if (calories > 0 && protein == 0 && carbs == 0 && fat == 0) {
      warnings.add(
        'Calories are greater than zero, but all macronutrients are zero.',
      );
    }

    if (warnings.isEmpty) {
      return true;
    }

    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Check Nutrition Values'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Some nutrition values may be incomplete or incorrect:',
              ),
              const SizedBox(height: 12),
              for (final warning in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $warning'),
                ),
              const SizedBox(height: 8),
              const Text(
                'Please verify the values for the exact portion '
                'you consumed before saving.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Edit Values'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Anyway'),
            ),
          ],
        );
      },
    );

    return shouldContinue ?? false;
  }

  Future<void> _confirmEntry() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    final shouldContinue = await _confirmSuspiciousNutrition();

    if (!mounted || !shouldContinue) return;

    final user = _firebaseAuth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save your food.')),
      );
      return;
    }

    final foodLog = FoodLogModel(
      foodId: _submissionId,
      foodName: _nameController.text.trim(),
      brand: null,
      source: 'Manual Entry',
      grams: double.parse(_gramsController.text.trim()),
      mealType: _mealType,
      calories: double.parse(_caloriesController.text.trim()),
      protein: double.parse(_proteinController.text.trim()),
      carbs: double.parse(_carbsController.text.trim()),
      fat: double.parse(_fatController.text.trim()),
      loggedAt: _submissionLoggedAt,
    );

    setState(() {
      _isSaving = true;
      _hasAttemptedSave = true;
    });

    try {
      await _foodLogRepository.saveFoodLog(
        userId: user.uid,
        foodLog: foodLog,
        submissionId: _submissionId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${foodLog.foodName} saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );

      // Return to Food Scanner.
      // The parent page already refreshes Recently Logged.
      Navigator.pop(context, true);
    } on StateError catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This food entry may already be saved. '
            'Please check Food History before trying again.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save food. Please check your connection '
            'and try again.',
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(title: const Text('Manual Food Entry'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Enter food information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter nutrition values for the exact portion '
              'you consumed, not per 100 g.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Once saving has been attempted, keep the
            // original food details unchanged for retries.
            AbsorbPointer(
              absorbing: _hasAttemptedSave,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      hintText: 'e.g. Rice and Dhal Curry',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.isEmpty) {
                        return 'Enter food name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _numberField(
                    'Portion Size',
                    _gramsController,
                    'g',
                    isGrams: true,
                  ),

                  const SizedBox(height: 14),

                  _numberField('Calories', _caloriesController, 'kcal'),

                  const SizedBox(height: 14),

                  _numberField('Protein', _proteinController, 'g'),

                  const SizedBox(height: 14),

                  _numberField('Carbohydrates', _carbsController, 'g'),

                  const SizedBox(height: 14),

                  _numberField('Fat', _fatController, 'g'),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _mealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Breakfast',
                        child: Text('Breakfast'),
                      ),
                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _mealType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            if (_hasAttemptedSave && !_isSaving) ...[
              const SizedBox(height: 14),
              const Text(
                'Food details are locked for this submission. '
                'You can retry saving the same food details.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final shouldLeave = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Start a New Entry?'),
                      content: const Text(
                        'Your previous food entry may already have '
                        'been saved. Check Food History before '
                        'creating another entry to avoid duplicates.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Keep This Entry'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Leave Entry'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLeave == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Start New Entry'),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _confirmEntry,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving Food...' : 'Save Food'),
            ),
          ],
        ),
      ),
    );
  }
}
