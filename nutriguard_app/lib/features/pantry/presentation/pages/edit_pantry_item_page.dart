import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/pantry_item_model.dart';
import '../../data/repositories/pantry_repository.dart';

class EditPantryItemPage extends StatefulWidget {
  final PantryItemModel item;

  const EditPantryItemPage({super.key, required this.item});

  @override
  State<EditPantryItemPage> createState() => _EditPantryItemPageState();
}

class _EditPantryItemPageState extends State<EditPantryItemPage> {
  static const Color primary = Color(0xFF0D9488);
  static const Color background = Color(0xFFF7FAFA);

  final _formKey = GlobalKey<FormState>();
  final PantryRepository _repository = PantryRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _lowStockController;

  late String _selectedUnit;
  late String _selectedCategory;

  DateTime? _expiryDate;
  bool _isSaving = false;

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
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.item.name);

    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );

    // Load the previously saved minimum stock level.
    _lowStockController = TextEditingController(
      text: widget.item.lowStockThreshold?.toString() ?? '',
    );

    _selectedUnit = widget.item.unit;
    _selectedCategory = widget.item.category;
    _expiryDate = widget.item.expiryDate;
  }

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
    if (_isSaving) return;

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

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update your pantry.')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());

    if (quantity == null) return;

    final lowStockText = _lowStockController.text.trim();

    // Empty input means the user wants no minimum stock level.
    final double? lowStockThreshold = lowStockText.isEmpty
        ? null
        : double.tryParse(lowStockText);

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text.trim(),
        quantity: quantity,
        unit: _selectedUnit,
        category: _selectedCategory,
        expiryDate: _expiryDate,
        clearExpiryDate: _expiryDate == null,
        lowStockThreshold: lowStockThreshold,
        clearLowStockThreshold: lowStockThreshold == null,
      );

      await _repository.updatePantryItem(userId: user.uid, item: updatedItem);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient updated successfully!')),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update ingredient: $error')),
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
    final availableUnits = _units.contains(_selectedUnit)
        ? _units
        : [..._units, _selectedUnit];

    final availableCategories = _categories.contains(_selectedCategory)
        ? _categories
        : [..._categories, _selectedCategory];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Edit Ingredient'),
        centerTitle: true,
        backgroundColor: background,
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
                child: Icon(Icons.edit_note, size: 35, color: primary),
              ),

              const SizedBox(height: 16),

              const Text(
                'Update Ingredient',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage your available quantity, minimum '
                'stock level, and expiry date.',
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
                  prefixIcon: Icon(Icons.restaurant_outlined),
                  border: OutlineInputBorder(),
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
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
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

              // Measurement unit.
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: availableUnits.map((unit) {
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

              // Ingredient category.
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: availableCategories.map((category) {
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

              // NEW: Editable minimum stock level.
              TextFormField(
                controller: _lowStockController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Minimum Stock Level (Optional)',
                  hintText: 'Example: 6',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: const OutlineInputBorder(),
                  suffixText: _selectedUnit,
                  helperText:
                      'A Running Low warning will appear when '
                      'available quantity reaches this level.',
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  // Empty means remove the threshold.
                  if (text.isEmpty) return null;

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
                  onPressed: _isSaving ? null : _saveChanges,
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
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
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
