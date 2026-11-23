import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/food_model.dart';
import '../../data/repositories/food_repository.dart';
import '../widgets/food_portion_sheet.dart';
import '../../data/models/food_log_model.dart';
import '../../data/repositories/food_log_repository.dart';
import '../../data/services/food_log_photo_service.dart';
import '../../../nutrition/presentation/pages/nutrition_analysis_page.dart';
import 'manual_food_entry_page.dart';

class FoodSearchPage extends StatefulWidget {
  final String? initialQuery;
  final XFile? selectedPhoto;

  const FoodSearchPage({super.key, this.initialQuery, this.selectedPhoto});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final FoodRepository _foodRepository = FoodRepository();

  final FoodLogRepository _foodLogRepository = FoodLogRepository();

  final FoodLogPhotoService _photoService = FoodLogPhotoService();

  bool _isSavingFood = false;

  List<FoodModel> _foods = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();

    final initialQuery = widget.initialQuery?.trim();

    if (initialQuery == null || initialQuery.isEmpty) {
      return;
    }

    _searchController.text = initialQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _searchFoods();
    });
  }

  Future<void> _searchFoods() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _foods = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    final requestId = ++_searchRequestId;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _foods = [];
    });

    FocusScope.of(context).unfocus();

    try {
      final results = await _foodRepository.searchFoods(query);

      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _foods = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to search foods. Check your internet '
            'connection and try again.';
      });
    }
  }

  void _clearSearch() {
    _searchRequestId++;

    _searchController.clear();

    setState(() {
      _foods = [];
      _isLoading = false;
      _hasSearched = false;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _searchRequestId++;
    _searchController.dispose();
    _foodRepository.dispose();
    super.dispose();
  }

  Future<void> _openPortionSheet(FoodModel food) async {
    if (_isSavingFood) return;

    final selection = await showModalBottomSheet<FoodPortionSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FoodPortionSheet(food: food),
    );

    if (!mounted || selection == null || _isSavingFood) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save your food.')),
      );
      return;
    }

    setState(() {
      _isSavingFood = true;
    });

    final selectedFood = selection.food;
    final grams = selection.grams;

    final foodLog = FoodLogModel(
      foodId: selectedFood.id,
      foodName: selectedFood.name,
      brand: selectedFood.brand,
      source: selectedFood.source,
      grams: grams,
      mealType: selection.mealType,
      calories: selectedFood.caloriesForGrams(grams),
      protein: selectedFood.proteinForGrams(grams),
      carbs: selectedFood.carbsForGrams(grams),
      fat: selectedFood.fatForGrams(grams),
      loggedAt: DateTime.now(),
    );

    try {
      final documentId = await _foodLogRepository.saveFoodLog(
        userId: user.uid,
        foodLog: foodLog,
      );

      bool photoSaved = true;

      if (widget.selectedPhoto != null) {
        try {
          await _photoService.savePhoto(
            userId: user.uid,
            documentId: documentId,
            photo: widget.selectedPhoto!,
          );
        } catch (error) {
          photoSaved = false;

          debugPrint('Food photo could not be saved: $error');
        }
      }

      if (!mounted) return;

      if (!photoSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Food logged successfully, but the photo '
              'could not be saved on this device.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // When opened from AI recognition, show Nutrition Analysis
      // after the food log and its photo have been saved.
      if (widget.initialQuery?.trim().isNotEmpty == true) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => NutritionAnalysisPage(
              foodLog: foodLog,
              foodLogDocumentId: documentId,
            ),
          ),
        );

        if (!mounted) return;

        // Return the successful save result to FoodPhotoPage.
        Navigator.pop(context, true);
        return;
      }

      // Normal Food Search behavior remains unchanged.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedFood.name} added to your food log!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save food. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingFood = false;
        });
      }
    }
  }

  Widget _buildFoodCard(FoodModel food) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isSavingFood ? null : () => _openPortionSheet(food),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),

              if (food.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  food.brand!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 10),

              const Text(
                'Nutrition per 100 g',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _nutritionLabel(
                    'Calories',
                    '${food.caloriesPer100g.toStringAsFixed(1)} kcal',
                  ),
                  _nutritionLabel(
                    'Protein',
                    '${food.proteinPer100g.toStringAsFixed(1)} g',
                  ),
                  _nutritionLabel(
                    'Carbs',
                    '${food.carbsPer100g.toStringAsFixed(1)} g',
                  ),
                  _nutritionLabel(
                    'Fat',
                    '${food.fatPer100g.toStringAsFixed(1)} g',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                'Source: ${food.source}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionLabel(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Future<void> _openManualEntry() async {
    final foodName = _searchController.text.trim();

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualFoodEntryPage(
          initialFoodName: foodName.isEmpty ? null : foodName,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      // Return to AI workflow when Manual Entry saved successfully.
      if (widget.initialQuery != null) {
        Navigator.pop(context, true);
        return;
      }

      // Keep the normal Search tab behavior unchanged.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual food entry saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _searchFoods,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Search for a food to view its nutrition.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_foods.isEmpty) {
      return const Center(
        child: Text(
          'No foods with complete nutrition information '
          'were found. Try another search term.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: _foods.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(_foods[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Search Food'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchFoods(),
              decoration: InputDecoration(
                hintText: 'Search food (e.g. oats, cereal)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchFoods,
                icon: const Icon(Icons.search),
                label: const Text('Search Food'),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _openManualEntry,
              icon: const Icon(Icons.edit_note),
              label: const Text("Can't find your food? Enter manually"),
            ),

            const SizedBox(height: 16),

            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }
}
