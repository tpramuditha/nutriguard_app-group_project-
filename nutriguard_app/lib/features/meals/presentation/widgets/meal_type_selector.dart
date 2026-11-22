import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class MealTypeSelector extends StatelessWidget {
  final String selectedMeal;
  final ValueChanged<String> onMealSelected;

  const MealTypeSelector({
    super.key,
    required this.selectedMeal,
    required this.onMealSelected,
  });

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: mealTypes.map((meal) {
          final isSelected = selectedMeal == meal;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(meal),
              selected: isSelected,
              onSelected: (_) => onMealSelected(meal),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFC6E4E6),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }
}
