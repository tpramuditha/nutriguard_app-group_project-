import 'package:flutter/material.dart';

import '../../data/services/recipe_health_marker_loader.dart';

class RecipeHealthContextCard extends StatefulWidget {
  const RecipeHealthContextCard({
    super.key,
    this.healthDataFuture,
    this.referenceDate,
  });

  // Optional inputs for testing.
  // Production continues to load data from Firebase.
  final Future<bool>? healthDataFuture;
  final DateTime? referenceDate;

  @override
  State<RecipeHealthContextCard> createState() =>
      _RecipeHealthContextCardState();
}

class _RecipeHealthContextCardState extends State<RecipeHealthContextCard> {
  static const Color primary = Color(0xFF0D9488);
  static const Color darkGreen = Color(0xFF086F67);

  late Future<bool> _hasHealthDataFuture;
  late String _monthId;
  late String _monthLabel;

  @override
  void initState() {
    super.initState();
    _loadCurrentMonth();
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  void _loadCurrentMonth() {
    final now = widget.referenceDate ?? DateTime.now();

    _monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    _monthLabel = '${_monthName(now.month)} ${now.year}';

    _hasHealthDataFuture =
        widget.healthDataFuture ??
        RecipeHealthMarkerLoader().hasHealthData(month: _monthId);
  }

  void _refresh() {
    setState(_loadCurrentMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline, color: primary, size: 23),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Health Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
              Text(
                _monthLabel,
                style: const TextStyle(color: Color(0xFF71858A), fontSize: 12),
              ),
              IconButton(
                tooltip: 'Refresh health markers',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 19, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FutureBuilder<bool>(
            future: _hasHealthDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Checking monthly health markers...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to load health markers. '
                        'Check your connection and refresh.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF975D1B),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final hasData = snapshot.data ?? false;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasData ? Icons.check_circle_outline : Icons.info_outline,
                    size: 19,
                    color: hasData
                        ? const Color(0xFF168653)
                        : const Color(0xFFB47A23),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasData
                          ? 'Health markers recorded for $_monthLabel.'
                          : 'No health markers recorded for $_monthLabel.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasData
                            ? const Color(0xFF168653)
                            : const Color(0xFF986924),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 11),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text(
            'Recipes currently use pantry availability '
            'and estimated calories. Health measurements '
            'are not used to determine whether a recipe '
            'is medically suitable.',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: Color(0xFF71858A),
            ),
          ),
        ],
      ),
    );
  }
}
