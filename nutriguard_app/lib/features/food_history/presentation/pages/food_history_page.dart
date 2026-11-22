import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../food_scanner/data/models/food_log_model.dart';
import '../../../food_scanner/data/repositories/food_log_repository.dart';
import '../../../../app/routes/route_names.dart';
import '../../../nutrition/presentation/pages/nutrition_analysis_page.dart';

class FoodHistoryPage extends StatefulWidget {
  final FoodLogRepository? repository;
  final String? userId;

  const FoodHistoryPage({super.key, this.repository, this.userId});

  @override
  State<FoodHistoryPage> createState() => _FoodHistoryPageState();
}

class _FoodHistoryPageState extends State<FoodHistoryPage> {
  late final FoodLogRepository _repository;

  late Future<List<FoodLogRecord>> _logsFuture;

  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';
  bool _showTimeline = false;

  static const _filters = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? FoodLogRepository();

    _loadLogs();
  }

  void _loadLogs() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    _logsFuture = userId == null
        ? Future.error(StateError('Please log in to view food history.'))
        : _repository.getFoodLogRecords(userId: userId);
  }

  Future<void> _refresh() async {
    setState(_loadLogs);

    try {
      await _logsFuture;
    } catch (_) {
      // FutureBuilder displays the error message.
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + days,
      );
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateText(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final prefix = _sameDay(date, DateTime.now()) ? 'Today, ' : '';

    return '$prefix${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  List<FoodLogModel> _logsForDate(List<FoodLogModel> logs) {
    return logs.where((log) {
      return _sameDay(log.loggedAt.toLocal(), _selectedDate);
    }).toList();
  }

  List<FoodLogModel> _applyFilter(List<FoodLogModel> logs) {
    if (_selectedFilter == 'All') return logs;

    final mealType = _selectedFilter == 'Snacks' ? 'Snack' : _selectedFilter;

    return logs.where((log) => log.mealType == mealType).toList();
  }

  double _total(List<FoodLogModel> logs, double Function(FoodLogModel) value) {
    return logs.fold<double>(0, (sum, log) => sum + value(log));
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Food History Date',
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Widget _dateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeDate(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          _dateText(_selectedDate),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        IconButton(
          onPressed: () => _changeDate(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              selectedColor: const Color(0xFFD5EEE5),
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summary(List<FoodLogModel> logs) {
    final calories = _total(logs, (log) => log.calories);
    final protein = _total(logs, (log) => log.protein);
    final carbs = _total(logs, (log) => log.carbs);
    final fat = _total(logs, (log) => log.fat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Nutrition Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              Text('Protein ${protein.toStringAsFixed(1)} g'),
              Text('Carbs ${carbs.toStringAsFixed(1)} g'),
              Text('Fat ${fat.toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    );
  }

  IconData _mealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.wb_twilight;
      case 'Lunch':
        return Icons.wb_sunny_outlined;
      case 'Dinner':
        return Icons.nightlight_round;
      case 'Snack':
        return Icons.apple_outlined;
      default:
        return Icons.restaurant;
    }
  }

  Widget _foodTile(FoodLogModel log, {String? documentId}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => NutritionAnalysisPage(
                foodLog: log,
                foodLogDocumentId: documentId,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2EC),
          child: Icon(_mealIcon(log.mealType), color: AppColors.primary),
        ),
        title: Text(log.foodName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${log.grams.toStringAsFixed(0)} g'
          ' · ${log.loggedAt.toLocal().hour.toString().padLeft(2, '0')}:'
          '${log.loggedAt.toLocal().minute.toString().padLeft(2, '0')}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${log.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _listView(
    List<FoodLogModel> logs,
    Map<FoodLogModel, String> documentIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mealType in _mealTypes) ...[
          if (logs.any((log) => log.mealType == mealType)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mealType == 'Snack' ? 'Snacks' : mealType,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    '${_total(logs.where((log) => log.mealType == mealType).toList(), (log) => log.calories).toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (final log in logs)
              if (log.mealType == mealType)
                _foodTile(log, documentId: documentIds[log]),
          ],
        ],
      ],
    );
  }

  Widget _timelineView(
    List<FoodLogModel> logs,
    Map<FoodLogModel, String> documentIds,
  ) {
    final sorted = [...logs]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return Column(
      children: [
        for (final log in sorted) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              log.mealType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          _foodTile(log, documentId: documentIds[log]),
        ],
      ],
    );
  }

  Widget _historyContent(List<FoodLogRecord> records) {
    final allLogs = records.map((record) => record.foodLog).toList();

    final documentIds = <FoodLogModel, String>{
      for (final record in records) record.foodLog: record.documentId,
    };

    final dailyLogs = _logsForDate(allLogs);
    final visibleLogs = _applyFilter(dailyLogs);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('List'),
              icon: Icon(Icons.list),
            ),
            ButtonSegment(
              value: true,
              label: Text('Timeline'),
              icon: Icon(Icons.timeline),
            ),
          ],
          selected: {_showTimeline},
          onSelectionChanged: (selection) {
            setState(() => _showTimeline = selection.first);
          },
        ),
        const SizedBox(height: 14),
        _dateSelector(),
        const SizedBox(height: 10),
        _filterChips(),
        const SizedBox(height: 18),
        _summary(dailyLogs),
        const SizedBox(height: 20),

        if (visibleLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 45),
            child: Column(
              children: [
                Icon(
                  dailyLogs.isEmpty
                      ? Icons.no_meals_outlined
                      : Icons.filter_list_off,
                  size: 55,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  dailyLogs.isEmpty
                      ? 'No meals logged for this date.'
                      : 'No meals found for this meal type.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                if (dailyLogs.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        RouteNames.foodScanner,
                      );

                      if (!mounted) return;

                      await _refresh();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Log a Meal'),
                  ),
              ],
            ),
          )
        else if (_showTimeline)
          _timelineView(visibleLogs, documentIds)
        else
          _listView(visibleLogs, documentIds),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Food History'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Select date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<FoodLogRecord>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 55,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to Load Food History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Something went wrong while loading your food history. '
                      'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _historyContent(snapshot.data ?? []),
          );
        },
      ),
    );
  }
}
