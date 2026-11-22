import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../repositories/user_data_inventory_repository.dart';
import '../../data/services/user_data_export_service.dart';

class MyStoredDataPage extends StatefulWidget {
  const MyStoredDataPage({super.key});

  @override
  State<MyStoredDataPage> createState() => _MyStoredDataPageState();
}

class _MyStoredDataPageState extends State<MyStoredDataPage> {
  final UserDataInventoryRepository _repository = UserDataInventoryRepository();

  final UserDataExportService _exportService = UserDataExportService();

  late Future<UserDataInventory> _inventoryFuture;

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    _inventoryFuture = _repository.getInventory();
  }

  Future<void> _refreshInventory() async {
    setState(_loadInventory);
    await _inventoryFuture;
  }

  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await _exportService.createExportFile();

      if (!mounted) return;

      await _exportService.shareExportFile(file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export your data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  int _countFor(UserDataInventory inventory, List<String> collections) {
    return collections.fold(
      0,
      (total, name) => total + (inventory.collectionCounts[name] ?? 0),
    );
  }

  int _preferenceCount(UserDataInventory inventory) {
    return inventory.preferenceDocuments.values
        .where((exists) => exists)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFC),
        title: const Text(
          'My Stored Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<UserDataInventory>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final inventory = snapshot.data;

          if (inventory == null) {
            return _buildErrorState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshInventory,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(inventory),
                const SizedBox(height: 20),

                _buildExportCard(),

                const SizedBox(height: 20),

                const Text(
                  'Your Data Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),

                _buildDataItem(
                  icon: Icons.restaurant_outlined,
                  title: 'Food History',
                  description: 'Your logged meals and nutrition records.',
                  count: _countFor(inventory, ['foodLogs']),
                ),

                _buildDataItem(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Health Records',
                  description:
                      'Uploaded health reports and monthly health markers.',
                  count: _countFor(inventory, [
                    'healthReports',
                    'monthlyHealthMarkers',
                  ]),
                ),

                _buildDataItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Meal Plans',
                  description: 'Meals saved in your meal planner.',
                  count: _countFor(inventory, ['plannedMeals']),
                ),

                _buildDataItem(
                  icon: Icons.fitness_center_outlined,
                  title: 'Exercise Records',
                  description: 'Exercise logs and weekly exercise plans.',
                  count: _countFor(inventory, [
                    'exerciseLogs',
                    'weeklyExercisePlans',
                  ]),
                ),

                _buildDataItem(
                  icon: Icons.kitchen_outlined,
                  title: 'My Pantry',
                  description: 'Ingredients saved in your pantry.',
                  count: _countFor(inventory, ['pantryItems']),
                ),

                _buildDataItem(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Weight Records',
                  description: 'Your recorded weight measurements.',
                  count: _countFor(inventory, ['weightLogs']),
                ),

                _buildDataItem(
                  icon: Icons.tune_outlined,
                  title: 'Personal Preferences',
                  description:
                      'Nutrition goals, dietary and notification settings.',
                  count: _preferenceCount(inventory),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Your information is stored under your NutriGuard account. '
                  'Only your authenticated account can access these records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.file_download_outlined,
                color: AppColors.primary,
                size: 25,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Export My Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a CSV file containing your stored food, health, '
            'meal, exercise, weight and preference records.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                _isExporting ? 'Preparing Export...' : 'Export My Data',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Locally stored food images are not included in this export.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(UserDataInventory inventory) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F9F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0F0E8)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Stored Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${inventory.totalRecords} stored records and settings',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String title,
    required String description,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE9F9F5),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Records',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load your stored data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(_loadInventory);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
