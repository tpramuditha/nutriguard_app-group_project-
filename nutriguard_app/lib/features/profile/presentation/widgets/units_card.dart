import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class UnitsCard extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const UnitsCard({
    super.key,
    required this.selectedUnit,
    required this.onChanged,
    this.enabled = true,
  });

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
              Icon(Icons.scale_outlined, color: AppColors.primary, size: 26),
              SizedBox(width: 10),
              Text(
                'Units',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _unitButton(title: 'Metric (kg/g)', value: 'Metric'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _unitButton(
                  title: 'Imperial (lb/oz)',
                  value: 'Imperial',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitButton({required String title, required String value}) {
    final isSelected = selectedUnit == value;

    return OutlinedButton(
      onPressed: enabled && !isSelected ? () => onChanged(value) : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppColors.primaryDark,
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFB5E7D7),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
