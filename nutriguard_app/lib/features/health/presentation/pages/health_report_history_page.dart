import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/health_report_model.dart';
import '../../data/repositories/health_report_repository.dart';
import '../widgets/health_report_card.dart';
import 'health_report_detail_page.dart';

class HealthReportHistoryPage extends StatefulWidget {
  const HealthReportHistoryPage({super.key});

  @override
  State<HealthReportHistoryPage> createState() =>
      _HealthReportHistoryPageState();
}

class _HealthReportHistoryPageState extends State<HealthReportHistoryPage> {
  final HealthReportRepository _repository = HealthReportRepository();

  late Future<List<HealthReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _repository.getReports();
  }

  Future<void> _refreshReports() async {
    setState(() {
      _loadReports();
    });

    try {
      await _reportsFuture;
    } catch (_) {
      // FutureBuilder displays the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Health Report History'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReports,
        child: FutureBuilder<List<HealthReportModel>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'Unable to load health report history.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.history, size: 54, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No health reports recorded yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${reports.length} saved reports',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                for (final report in reports)
                  HealthReportCard(
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
