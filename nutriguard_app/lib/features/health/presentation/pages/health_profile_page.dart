import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/health_marker_card.dart';
import '../../../../app/routes/route_names.dart';
import '../../data/repositories/health_report_repository.dart';
import '../widgets/health_report_card.dart';
import 'health_report_detail_page.dart';
import '../../data/models/health_report_model.dart';
import 'health_report_history_page.dart';
import '../../data/models/monthly_health_marker_model.dart';
import '../../data/repositories/monthly_health_marker_repository.dart';
import 'health_marker_detail_page.dart';
import '../../data/models/health_measurement_model.dart';

class HealthProfilePage extends StatefulWidget {
  const HealthProfilePage({super.key});

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage> {
  final HealthReportRepository _reportRepository = HealthReportRepository();

  late Future<List<HealthReportModel>> _reportsFuture;

  final MonthlyHealthMarkerRepository _markerRepository =
      MonthlyHealthMarkerRepository();

  late Future<MonthlyHealthMarkerModel?> _markersFuture;
  // Start with the current month.
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _monthLabel {
    return '${_months[_selectedMonth.month - 1]} '
        '${_selectedMonth.year}';
  }

  String get _monthId {
    return '${_selectedMonth.year}-'
        '${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );

      _markersFuture = _markerRepository.getMarkers(_monthId);
    });
  }

  void _refreshHealthReports() {
    setState(() {
      _reportsFuture = _reportRepository.getReports();
    });
  }

  void _refreshMonthlyMarkers() {
    setState(() {
      _markersFuture = _markerRepository.getMarkers(_monthId);
    });
  }

  void _openMarkerDetails({
    required String title,
    required List<String> expectedNames,
    required List<HealthMeasurementModel> measurements,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthMarkerDetailPage(
          title: title,
          monthLabel: _monthLabel,
          measurements: measurements,
          expectedNames: expectedNames,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _reportsFuture = _reportRepository.getReports();
    _markersFuture = _markerRepository.getMarkers(_monthId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),

      appBar: AppBar(
        title: const Text(
          'Health Profile',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HealthReportHistoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('History'),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Monthly reminder

            FutureBuilder<MonthlyHealthMarkerModel?>(
              future: _markersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                final hasMarkers =
                    snapshot.data?.measurements.isNotEmpty ?? false;

                if (hasMarkers) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD6A1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFFF8A00),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No health markers recorded for this month yet.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAD5500),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final saved = await Navigator.pushNamed(
                            context,
                            RouteNames.logHealthMarker,
                            arguments: _selectedMonth,
                          );

                          if (!mounted) return;

                          if (saved == true) {
                            _refreshMonthlyMarkers();
                          }
                        },
                        child: const Text('Log Now'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // Month selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.primary,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _monthLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Example health markers — not actual records
            FutureBuilder<MonthlyHealthMarkerModel?>(
              future: _markersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Unable to load monthly health markers.',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final measurements = snapshot.data?.measurements ?? [];

                String? findValue(String name) {
                  for (final measurement in measurements) {
                    if (measurement.name == name) {
                      final value = measurement.value;

                      if (value == value.truncateToDouble()) {
                        return value.toStringAsFixed(0);
                      }

                      return value.toString();
                    }
                  }

                  return null;
                }

                final totalCholesterol = findValue('Total Cholesterol');

                final fastingGlucose = findValue('Fasting Blood Glucose');
                final randomGlucose = findValue('Random Blood Glucose');
                final afterMealGlucose = findValue('After Meal Blood Glucose');

                final glucoseValue =
                    fastingGlucose ?? randomGlucose ?? afterMealGlucose;

                final glucoseType = fastingGlucose != null
                    ? 'Fasting'
                    : randomGlucose != null
                    ? 'Random'
                    : 'After Meal';

                final systolic = findValue('Systolic Blood Pressure');
                final diastolic = findValue('Diastolic Blood Pressure');

                final hasCholesterol = measurements.any(
                  (m) => [
                    'Total Cholesterol',
                    'LDL Cholesterol',
                    'HDL Cholesterol',
                    'Triglycerides',
                  ].contains(m.name),
                );

                return Column(
                  children: [
                    HealthMarkerCard(
                      title: 'Cholesterol',
                      value: totalCholesterol != null
                          ? '$totalCholesterol mg/dL'
                          : hasCholesterol
                          ? 'Partially recorded'
                          : 'Not recorded',
                      lastLogged: hasCholesterol
                          ? 'Recorded for $_monthLabel'
                          : 'No measurements yet',
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFFFF7043),
                      onTap: () => _openMarkerDetails(
                        title: 'Cholesterol',
                        expectedNames: const [
                          'Total Cholesterol',
                          'LDL Cholesterol',
                          'HDL Cholesterol',
                          'Triglycerides',
                        ],
                        measurements: measurements,
                      ),
                    ),

                    const SizedBox(height: 12),

                    HealthMarkerCard(
                      title: 'Blood Sugar',
                      value: glucoseValue != null
                          ? '$glucoseValue mg/dL'
                          : 'Not recorded',
                      lastLogged: glucoseValue != null
                          ? '$glucoseType · $_monthLabel'
                          : 'No measurements yet',
                      icon: Icons.water_drop_outlined,
                      iconColor: const Color(0xFF2389E8),
                      onTap: () => _openMarkerDetails(
                        title: 'Blood Sugar',
                        expectedNames: const [
                          'Fasting Blood Glucose',
                          'Random Blood Glucose',
                          'After Meal Blood Glucose',
                        ],
                        measurements: measurements,
                      ),
                    ),

                    const SizedBox(height: 12),

                    HealthMarkerCard(
                      title: 'Blood Pressure',
                      value: systolic != null && diastolic != null
                          ? '$systolic/$diastolic mmHg'
                          : 'Not recorded',
                      lastLogged: systolic != null && diastolic != null
                          ? 'Recorded for $_monthLabel'
                          : 'No measurements yet',
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFF04468),
                      onTap: () => _openMarkerDetails(
                        title: 'Blood Pressure',
                        expectedNames: const [
                          'Systolic Blood Pressure',
                          'Diastolic Blood Pressure',
                        ],
                        measurements: measurements,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Other Health Reports section
            const Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Other Health Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            //additional reports saved
            FutureBuilder(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Unable to load health reports. Please try again.',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0EFF2)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          color: AppColors.textSecondary,
                          size: 38,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No additional health reports yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Add a laboratory report to track more health measurements.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: reports.map((report) {
                    return HealthReportCard(
                      report: report,

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HealthReportDetailPage(report: report),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 14),

            // Add Health Report button
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, RouteNames.addHealthReport);

                if (!mounted) return;

                _refreshHealthReports();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Health Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: () async {
                final saved = await Navigator.pushNamed(
                  context,
                  RouteNames.logHealthMarker,
                  arguments: _selectedMonth,
                );

                if (!mounted) return;

                if (saved == true) {
                  _refreshMonthlyMarkers();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Log This Month's Markers"),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.scanHealthReport);
              },
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Blood Report (Auto-fill)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'AI will suggest values — you confirm before saving',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 22),

            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE0F4ED),
                          child: Icon(
                            Icons.fitness_center,
                            color: Color(0xFF086F67),
                            size: 25,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Exercise Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF086F67),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Explore exercise recommendations based on '
                      'your fitness goals, activity level, and '
                      'exercise preferences.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.exerciseRecommendation,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('View Exercise Recommendations'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF086F67),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4B83B6)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is general wellness guidance, '
                      'not medical advice. Consult a doctor '
                      'for health decisions.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF4B83B6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
