import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DietaryRestrictionsCard extends StatelessWidget {
  final Set<String> selectedRestrictions;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  const DietaryRestrictionsCard({
    super.key,
    required this.selectedRestrictions,
    required this.onChanged,
    this.enabled = true,
  });

  static const List<String> _restrictions = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Pescatarian',
    'None',
  ];

  void _toggleRestriction(String restriction) {
    if (!enabled) return;

    final updatedRestrictions = Set<String>.from(selectedRestrictions);

    if (restriction == 'None') {
      updatedRestrictions
        ..clear()
        ..add('None');
    } else {
      updatedRestrictions.remove('None');

      if (updatedRestrictions.contains(restriction)) {
        updatedRestrictions.remove(restriction);
      } else {
        updatedRestrictions.add(restriction);
      }

      if (updatedRestrictions.isEmpty) {
        updatedRestrictions.add('None');
      }
    }

    onChanged(updatedRestrictions);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.primary, size: 26),
              SizedBox(width: 10),
              Text(
                'Dietary Restrictions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _restrictions.map((restriction) {
              final isSelected = selectedRestrictions.contains(restriction);

              return FilterChip(
                label: Text(restriction),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFB5E7D7),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                onSelected: enabled
                    ? (_) => _toggleRestriction(restriction)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
