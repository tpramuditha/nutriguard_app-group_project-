import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/food_model.dart';

class FoodPortionSelection {
  final FoodModel food;
  final double grams;
  final String mealType;

  const FoodPortionSelection({
    required this.food,
    required this.grams,
    required this.mealType,
  });
}

class FoodPortionSheet extends StatefulWidget {
  final FoodModel food;

  const FoodPortionSheet({super.key, required this.food});

  @override
  State<FoodPortionSheet> createState() => _FoodPortionSheetState();
}

class _FoodPortionSheetState extends State<FoodPortionSheet> {
  final TextEditingController _gramsController = TextEditingController(
    text: '150',
  );

  String _selectedPortion = 'Medium';
  String _selectedMealType = 'Breakfast';

  double _grams = 150;

  bool _nutritionSourceConfirmed = false;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _updateGrams(double value) {
    if (!value.isFinite || value <= 0 || value > 5000) {
      return;
    }

    setState(() {
      _grams = value;
      _gramsController.text = value.toStringAsFixed(0);
    });
  }

  void _selectPortion(String portion, double grams) {
    setState(() {
      _selectedPortion = portion;
    });

    _updateGrams(grams);
  }

  void _onGramsChanged(String value) {
    final parsed = double.tryParse(value);

    setState(() {
      if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed > 5000) {
        _grams = 0;
      } else {
        _grams = parsed;
      }

      _selectedPortion = 'Custom';
    });
  }

  Widget _nutritionItem(String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 5),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _portionButton(String label, double grams) {
    final selected = _selectedPortion == label;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => _selectPortion(label, grams),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : Colors.white,
          foregroundColor: selected ? Colors.white : AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final validPortion = _grams > 0 && _grams <= 5000;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Confirm food and portion details',
                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8D8A8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF906B22),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verify Nutrition Source',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Selected food: ${food.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (food.brand != null)
                      Text(
                        'Brand: ${food.brand}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    Text(
                      'Nutrition source: ${food.source}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The nutrition values belong to this database entry. '
                      'They may differ from your actual meal, especially '
                      'for homemade foods.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Nutrition for selected portion',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nutritionItem(
                    'Calories',
                    food.caloriesForGrams(_grams),
                    'kcal',
                  ),
                  _nutritionItem('Protein', food.proteinForGrams(_grams), 'g'),
                  _nutritionItem('Carbs', food.carbsForGrams(_grams), 'g'),
                  _nutritionItem('Fat', food.fatForGrams(_grams), 'g'),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Select Portion Size',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _portionButton('Small', 100),
                  const SizedBox(width: 8),
                  _portionButton('Medium', 150),
                  const SizedBox(width: 8),
                  _portionButton('Large', 200),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'Preset sizes are examples. Adjust grams for your actual portion.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              const Text(
                'Enter Exact Grams',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateGrams(_grams - 10),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),

                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      onChanged: _onGramsChanged,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => _updateGrams(_grams + 10),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Meal Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((
                  mealType,
                ) {
                  return ChoiceChip(
                    label: Text(mealType),
                    selected: _selectedMealType == mealType,
                    onSelected: (_) {
                      setState(() {
                        _selectedMealType = mealType;
                      });
                    },
                  );
                }).toList(),
              ),

              CheckboxListTile(
                value: _nutritionSourceConfirmed,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I checked that this nutrition entry is appropriate '
                  'for the food I consumed.',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (value) {
                  setState(() {
                    _nutritionSourceConfirmed = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: validPortion && _nutritionSourceConfirmed
                      ? () {
                          Navigator.pop(
                            context,
                            FoodPortionSelection(
                              food: food,
                              grams: _grams,
                              mealType: _selectedMealType,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Confirm Portion'),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Confirm to add this food to your log.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
