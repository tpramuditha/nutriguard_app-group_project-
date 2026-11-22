import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AllergiesCard extends StatelessWidget {
  final List<String> allergies;
  final Future<void> Function(List<String>) onChanged;
  final bool enabled;

  const AllergiesCard({
    super.key,
    required this.allergies,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _addAllergy(BuildContext context) async {
    if (!enabled) return;

    String allergyName = '';

    final newAllergy = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Food Allergy'),
          content: TextFormField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Allergy name',
              hintText: 'e.g. Milk',
            ),
            onChanged: (value) {
              allergyName = value;
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
                final name = allergyName.trim();

                if (name.isEmpty) return;

                Navigator.pop(dialogContext, name);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || newAllergy == null) return;

    final name = newAllergy.trim();

    if (name.isEmpty) return;

    final alreadyExists = allergies.any(
      (allergy) => allergy.toLowerCase() == name.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This allergy is already added.')),
      );
      return;
    }

    if (allergies.length >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 30 allergies.')),
      );
      return;
    }

    await onChanged([...allergies, name]);
  }

  Future<void> _removeAllergy(String allergy) async {
    if (!enabled) return;

    final updatedAllergies = List<String>.from(allergies)..remove(allergy);

    await onChanged(updatedAllergies);
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Allergies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (allergies.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No allergies added',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allergies.map((allergy) {
              return Chip(
                label: Text(allergy),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: enabled ? () => _removeAllergy(allergy) : null,
                backgroundColor: const Color(0xFFFFF2E8),
                deleteIconColor: const Color(0xFFE65100),
                labelStyle: const TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w500,
                ),
                side: const BorderSide(color: Color(0xFFFFD5B2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: enabled ? () => _addAllergy(context) : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Allergy'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
