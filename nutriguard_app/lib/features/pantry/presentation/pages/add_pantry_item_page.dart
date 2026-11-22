import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/pantry_item_model.dart';
import '../../data/repositories/pantry_repository.dart';

class AddPantryItemPage extends StatefulWidget {
  const AddPantryItemPage({super.key});

  @override
  State<AddPantryItemPage> createState() => _AddPantryItemPageState();
}

class _AddPantryItemPageState extends State<AddPantryItemPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  // NEW: Optional minimum stock level.
  final _lowStockController = TextEditingController();

  final PantryRepository _repository = PantryRepository();

  String _selectedUnit = 'pcs';
  String _selectedCategory = 'Other';

  DateTime? _expiryDate;
  bool _isSaving = false;

  static const Color primary = Color(0xFF0D9488);

  static const List<String> _units = ['pcs', 'g', 'kg', 'ml', 'L'];

  static const List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Protein',
    'Dairy',
    'Grains',
    'Beverages',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectExpiryDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _expiryDate = selected;
    });
  }

  Future<void> _saveIngredient() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add ingredients.')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());

    if (quantity == null) return;

    final lowStockText = _lowStockController.text.trim();

    // The threshold is null when the optional field is empty.
    final double? lowStockThreshold = lowStockText.isEmpty
        ? null
        : double.tryParse(lowStockText);

    setState(() {
      _isSaving = true;
    });

    try {
      final item = PantryItemModel(
        id: '',
        name: _nameController.text.trim(),
        quantity: quantity,
        unit: _selectedUnit,
        category: _selectedCategory,
        expiryDate: _expiryDate,
        createdAt: DateTime.now(),
        lowStockThreshold: lowStockThreshold,
      );

      await _repository.addPantryItem(userId: user.uid, item: item);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient added successfully!')),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save ingredient: $error')),
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
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: const Text('Add Ingredient'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7FAFA),
        foregroundColor: const Color(0xFF086F67),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFD9F5EC),
                child: Icon(Icons.kitchen_outlined, size: 34, color: primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to My Pantry',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your ingredients and receive '
                'low-stock and expiry warnings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // Ingredient name.
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name',
                  hintText: 'Example: Eggs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an ingredient name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Available quantity.
              TextFormField(
                controller: _quantityController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Available Quantity',
                  hintText: 'Example: 4',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  final quantity = double.tryParse(value?.trim() ?? '');

                  if (quantity == null ||
                      !quantity.isFinite ||
                      quantity <= 0 ||
                      quantity > 1000000) {
                    return 'Enter a valid positive quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Unit.
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 18),

              // Category.
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 24),

              // NEW: Minimum stock level.
              TextFormField(
                controller: _lowStockController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Minimum Stock Level (Optional)',
                  hintText: 'Example: 6',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  helperText:
                      'Get a Running Low warning when quantity '
                      'reaches this level.',
                  helperMaxLines: 2,
                  suffixText: _selectedUnit,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return null;
                  }

                  final threshold = double.tryParse(text);

                  if (threshold == null ||
                      !threshold.isFinite ||
                      threshold < 0 ||
                      threshold > 1000000) {
                    return 'Enter a value between 0 and 1000000';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Optional expiry date.
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _selectExpiryDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _expiryDate == null
                      ? 'Select Expiry Date (Optional)'
                      : 'Expiry: ${_formatDate(_expiryDate!)}',
                ),
              ),

              if (_expiryDate != null)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _expiryDate = null;
                          });
                        },
                  child: const Text('Remove Expiry Date'),
                ),

              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveIngredient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Ingredient',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
