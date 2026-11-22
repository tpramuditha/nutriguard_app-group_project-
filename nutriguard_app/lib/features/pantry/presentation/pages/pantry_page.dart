import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/pantry_item_model.dart';
import '../../data/repositories/pantry_repository.dart';
import 'add_pantry_item_page.dart';
import 'edit_pantry_item_page.dart';
import 'recipes_page.dart';

class PantryPage extends StatefulWidget {
  final PantryRepository? repository;
  final FirebaseAuth? firebaseAuth;

  const PantryPage({super.key, this.repository, this.firebaseAuth});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  static const Color primary = Color(0xFF0D9488);
  static const Color darkGreen = Color(0xFF086F67);
  static const Color background = Color(0xFFF7FAFA);

  late final PantryRepository _repository =
      widget.repository ?? PantryRepository();

  FirebaseAuth get _auth => widget.firebaseAuth ?? FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  final Set<String> _collapsedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddPage() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddPantryItemPage()));
  }

  Future<void> _openEditPage(PantryItemModel item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditPantryItemPage(item: item)),
    );
  }

  Future<void> _deleteItem(PantryItemModel item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Ingredient?'),
        content: Text('Remove ${item.name} from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deletePantryItem(userId: user.uid, itemId: item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} removed successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete ingredient: $error')),
      );
    }
  }

  // REAL low-stock logic from PantryItemModel.
  bool _isRunningLow(PantryItemModel item) {
    return item.isRunningLow;
  }

  List<PantryItemModel> _filterItems(List<PantryItemModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case 'Running Low':
          return _isRunningLow(item);

        case 'Expiring Soon':
          return item.isExpiringSoon || item.isExpired;

        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<PantryItemModel>> _groupItems(List<PantryItemModel> items) {
    final grouped = <String, List<PantryItemModel>>{};

    for (final item in items) {
      final category = _displayCategory(item.category);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return grouped;
  }

  String _displayCategory(String category) {
    switch (category.toLowerCase()) {
      case 'grains':
        return 'Grains & Rice';
      case 'protein':
        return 'Proteins';
      case 'other':
        return 'Spices & Others';
      default:
        return category;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grains & rice':
        return Icons.grain;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'proteins':
        return Icons.egg_alt;
      case 'dairy':
        return Icons.local_drink;
      case 'beverages':
        return Icons.local_cafe;
      default:
        return Icons.kitchen;
    }
  }

  IconData _ingredientIcon(PantryItemModel item) {
    switch (item.category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco_outlined;
      case 'fruits':
        return Icons.apple_outlined;
      case 'protein':
        return Icons.egg_alt_outlined;
      case 'dairy':
        return Icons.local_drink_outlined;
      case 'grains':
        return Icons.grain;
      case 'beverages':
        return Icons.local_cafe_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toString();
  }

  String _expiryLabel(PantryItemModel item) {
    if (item.expiryDate == null) return 'No expiry';

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiry = DateTime(
      item.expiryDate!.year,
      item.expiryDate!.month,
      item.expiryDate!.day,
    );

    final days = expiry.difference(today).inDays;

    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Exp: 1 day';
    if (days < 7) return 'Exp: $days days';
    if (days < 14) return 'Exp: 1 week';
    if (days < 30) {
      return 'Exp: ${(days / 7).floor()} weeks';
    }

    return 'Exp: ${(days / 30).floor()} months';
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search pantry items',
        prefixIcon: const Icon(Icons.search, color: primary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFD8E8E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFD8E8E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primary),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = ['All', 'Running Low', 'Expiring Soon'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              selectedColor: primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : darkGreen,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              side: const BorderSide(color: Color(0xFFD7E8E5)),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16B7A2), Color(0xFFFFB86A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.restaurant_menu, color: primary),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Find recipes you can make right now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RecipesPage()),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Suggest Recipes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningLowNotice(List<PantryItemModel> items) {
    final lowItems = items.where(_isRunningLow).toList();

    if (lowItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final names = lowItems.take(3).map((item) => item.name).join(', ');

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = 'Running Low';
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE68A17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${lowItems.length} item(s) running low: $names',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B591C)),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE68A17)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientRow(PantryItemModel item) {
    final isUrgent = item.isExpired || item.isExpiringSoon;
    final isLow = _isRunningLow(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F6EF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_ingredientIcon(item), color: primary, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF183F43),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatQuantity(item.quantity)} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF698086),
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Running Low · Minimum: '
                    '${_formatQuantity(item.lowStockThreshold!)} '
                    '${item.unit}',
                    style: const TextStyle(
                      color: Color(0xFFE08019),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUrgent || isLow)
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(Icons.circle, color: Colors.orange, size: 7),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFFEBDD)
                    : const Color(0xFFEDF5F8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                _expiryLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isUrgent
                      ? const Color(0xFFD56C16)
                      : const Color(0xFF57737D),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ingredient options',
            icon: const Icon(
              Icons.more_vert,
              size: 19,
              color: Color(0xFF53757A),
            ),
            onSelected: (action) {
              if (action == 'edit') {
                _openEditPage(item);
              } else if (action == 'delete') {
                _deleteItem(item);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<PantryItemModel> items) {
    final collapsed = _collapsedCategories.contains(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EFEF)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (collapsed) {
                  _collapsedCategories.remove(category);
                } else {
                  _collapsedCategories.add(category);
                }
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(_categoryIcon(category), color: darkGreen, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17454A),
                      ),
                    ),
                  ),
                  Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF68858A),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed) ...[
            const Divider(height: 1),
            for (var i = 0; i < items.length; i++) ...[
              _buildIngredientRow(items[i]),
              if (i < items.length - 1) const Divider(height: 1, indent: 64),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching =
        _searchController.text.trim().isNotEmpty || _selectedFilter != 'All';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          const Icon(Icons.kitchen_outlined, size: 56, color: primary),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'No matching ingredients' : 'Your pantry is empty',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try another search or filter.'
                : 'Add your first ingredient to get started.',
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openAddPage,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPantryContent(List<PantryItemModel> allItems) {
    final filteredItems = _filterItems(allItems);
    final groupedItems = _groupItems(filteredItems);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFilters(),
        const SizedBox(height: 14),
        _buildRecipeBanner(),
        const SizedBox(height: 10),
        _buildRunningLowNotice(allItems),
        const SizedBox(height: 14),
        if (filteredItems.isEmpty)
          _buildEmptyState()
        else
          for (final entry in groupedItems.entries)
            _buildCategorySection(entry.key, entry.value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        centerTitle: true,
        title: const Text(
          'My Pantry',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Add ingredient',
            icon: const Icon(Icons.add, color: primary),
            onPressed: user == null ? null : _openAddPage,
          ),
        ],
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              onPressed: _openAddPage,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
      body: user == null
          ? const Center(child: Text('Please log in to view your pantry.'))
          : StreamBuilder<List<PantryItemModel>>(
              stream: _repository.watchPantryItems(userId: user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load pantry: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                return _buildPantryContent(snapshot.data!);
              },
            ),
    );
  }
}
