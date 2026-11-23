import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'food_confirmation_page.dart';
import 'food_search_page.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/food_recognition_service.dart';

class FoodPhotoPage extends StatefulWidget {
  const FoodPhotoPage({super.key});

  @override
  State<FoodPhotoPage> createState() => _FoodPhotoPageState();
}

class _FoodPhotoPageState extends State<FoodPhotoPage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isPicking = false;

  bool _isRecognizing = false;

  final FoodRecognitionService _recognitionService = FoodRecognitionService();

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to select photo. Check camera permission '
            'and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<bool> _showRecognitionError(String message) async {
    if (!mounted) return false;

    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Food Recognition Failed')),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );

    return retry ?? false;
  }

  Future<void> _recognizeFoodWithAI() async {
    if (_selectedImage == null || _isRecognizing) {
      return;
    }

    setState(() {
      _isRecognizing = true;
    });

    try {
      final result = await _recognitionService.recognizeFood(_selectedImage!);

      if (!mounted) return;

      if (result.foods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No food was identified. Try another photo.'),
          ),
        );
        return;
      }

      final confirmedFoods = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(builder: (_) => FoodConfirmationPage(result: result)),
      );

      if (!mounted || confirmedFoods == null) return;

      if (confirmedFoods.isEmpty) return;

      // Keep track of confirmed foods that have not been logged or skipped.
      final remainingFoods = List<String>.from(confirmedFoods);

      int savedCount = 0;

      while (mounted && remainingFoods.isNotEmpty) {
        final int? choice = await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return SimpleDialog(
              title: const Text('Choose Food to Log'),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Choose a food to log, skip a food, '
                    'or finish logging.',
                  ),
                ),

                for (var i = 0; i < remainingFoods.length; i++)
                  ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: Text(remainingFoods[i]),
                    onTap: () {
                      // A non-negative number means: log this food.
                      Navigator.pop(dialogContext, i);
                    },
                    trailing: IconButton(
                      tooltip: 'Skip ${remainingFoods[i]}',
                      icon: const Icon(Icons.skip_next_outlined),
                      onPressed: () {
                        // Negative numbers below -1 mean: skip this food.
                        Navigator.pop(dialogContext, -(i + 2));
                      },
                    ),
                  ),

                TextButton(
                  onPressed: () {
                    // -1 means: finish logging.
                    Navigator.pop(dialogContext, -1);
                  },
                  child: const Text('Finish Logging'),
                ),
              ],
            );
          },
        );

        if (!mounted || choice == null || choice == -1) {
          break;
        }

        // Skip the selected food without saving it.
        if (choice <= -2) {
          final skipIndex = -choice - 2;

          if (skipIndex >= 0 && skipIndex < remainingFoods.length) {
            remainingFoods.removeAt(skipIndex);
          }

          continue;
        }

        if (choice >= remainingFoods.length) {
          break;
        }

        final selectedFoodName = remainingFoods[choice];

        // FoodSearchPage returns true only after successful saving.
        final bool? saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => FoodSearchPage(
              initialQuery: selectedFoodName,
              selectedPhoto: _selectedImage,
            ),
          ),
        );

        if (!mounted) return;

        if (saved == true) {
          remainingFoods.removeAt(choice);
          savedCount++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$selectedFoodName logged successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        // If the user presses Back without saving, keep the food
        // in the list so they can retry or skip it.
      }

      if (!mounted) return;

      if (savedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$savedCount food${savedCount == 1 ? '' : 's'} '
              'logged successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      final retry = await _showRecognitionError(
        error.toString().replaceFirst('Exception: ', ''),
      );

      if (!mounted) return;

      if (retry) {
        setState(() {
          _isRecognizing = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _recognizeFoodWithAI();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(title: const Text('Scan Food Photo'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Identify Food from a Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a clear picture of your meal or '
              'choose an existing photo.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),

            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0EFF2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 70,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No photo selected',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  : Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Center(child: Text('Unable to preview image')),
                    ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPicking
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            if (_isPicking) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isRecognizing ? null : _recognizeFoodWithAI,
                icon: _isRecognizing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isRecognizing
                      ? 'Recognizing Food...'
                      : 'Recognize Food with AI',
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (_selectedImage != null) ...[
              const SizedBox(height: 22),
              const Text(
                'Photo selected successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your selected photo will be sent securely to our AI service '
                'when you tap Recognize Food with AI.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
