import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/food_recognition_result.dart';

class FoodConfirmationPage extends StatefulWidget {
  final FoodRecognitionResult result;

  const FoodConfirmationPage({super.key, required this.result});

  @override
  State<FoodConfirmationPage> createState() => _FoodConfirmationPageState();
}

class _FoodConfirmationPageState extends State<FoodConfirmationPage> {
  late final List<TextEditingController> _nameControllers;
  late final List<bool> _selectedFoods;

  @override
  void initState() {
    super.initState();

    _nameControllers = widget.result.foods
        .map((food) => TextEditingController(text: food.name))
        .toList();

    _selectedFoods = List<bool>.filled(widget.result.foods.length, false);
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  String _confidenceText(String confidence) {
    switch (confidence) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Medium confidence';
      case 'low':
        return 'Low confidence';
      default:
        return 'Uncertain';
    }
  }

  void _confirmFoods() {
    final selectedNames = <String>[];

    for (var i = 0; i < _selectedFoods.length; i++) {
      if (!_selectedFoods[i]) continue;

      final name = _nameControllers[i].text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a name for each selected food.'),
          ),
        );
        return;
      }

      selectedNames.add(name);
    }

    if (selectedNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one food.')),
      );
      return;
    }

    // Return confirmed names to the previous page.
    // Nutrition lookup and logging will be connected later.
    Navigator.pop(context, selectedNames);
  }

  Widget _foodCard(int index) {
    final food = widget.result.foods[index];

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: _selectedFoods[index],
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: Text(
                food.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              subtitle: Text(_confidenceText(food.confidence)),
              onChanged: (value) {
                setState(() {
                  _selectedFoods[index] = value ?? false;
                });
              },
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _nameControllers[index],
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Correct Food Name',
                border: OutlineInputBorder(),
                helperText: 'Edit if AI identified it incorrectly',
              ),
            ),

            if (food.alternativeNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Other names: ${food.alternativeNames.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            if (food.visibleIngredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'AI suggested ingredients: '
                '${food.visibleIngredients.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Confirm Identified Foods'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Review AI Food Suggestions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select the foods that are actually present. '
                  'Correct any incorrect names before continuing.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 20),

                for (var i = 0; i < widget.result.foods.length; i++)
                  _foodCard(i),

                if (widget.result.uncertainties.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  const Text(
                    'AI Uncertainties',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  for (final uncertainty in widget.result.uncertainties)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(uncertainty)),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 14),

                const Text(
                  'AI identification is a suggestion, not a '
                  'verified nutrition measurement.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmFoods,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Selected Foods'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
