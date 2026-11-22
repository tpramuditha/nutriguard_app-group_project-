import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/report_measurement_fields.dart';
import '../widgets/custom_measurement_fields.dart';
import '../../data/models/health_measurement_model.dart';
import '../../data/models/health_report_model.dart';
import '../../data/repositories/health_report_repository.dart';

class AddHealthReportPage extends StatefulWidget {
  final HealthReportRepository? repository;

  const AddHealthReportPage({super.key, this.repository});

  @override
  State<AddHealthReportPage> createState() => _AddHealthReportPageState();
}

class _AddHealthReportPageState extends State<AddHealthReportPage> {
  String _selectedReport = 'Lipid Profile';
  final Map<String, String> _enteredMeasurements = {};
  String _customReportName = '';

  List<Map<String, String>> _customMeasurements = [];

  // Repository used to communicate with Cloud Firestore.
  late final HealthReportRepository _reportRepository;

  // Tracks whether a report is currently being saved.
  bool _isSaving = false;

  DateTime _reportDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reportRepository = widget.repository ?? HealthReportRepository();
  }

  Future<void> _selectReportDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _reportDate = selectedDate;
      });
    }
  }

  String get _formattedReportDate {
    final day = _reportDate.day.toString().padLeft(2, '0');
    final month = _reportDate.month.toString().padLeft(2, '0');

    return '$day/$month/${_reportDate.year}';
  }

  final List<String> _reportTypes = [
    'Lipid Profile',
    'Blood Glucose / HbA1c',
    'Kidney Function',
    'Liver Function',
    'Thyroid Profile',
    'Complete Blood Count',
    'Custom Report',
  ];

  void _onMeasurementChanged(
    String measurementName,
    String value,
    String unit,
  ) {
    if (value.trim().isEmpty) {
      _enteredMeasurements.remove(measurementName);
    } else {
      _enteredMeasurements[measurementName] = value.trim();
    }
  }

  Future<void> _saveConfirmedReport(HealthReportModel report) async {
    if (_isSaving) return;

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      await _reportRepository.saveReport(report);

      if (!mounted) return;

      // Return to Health Profile after saving successfully.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save the report. '
            'Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _validateAndConfirm() async {
    if (_isSaving) return;

    String reportName;

    final List<HealthMeasurementModel> measurements = [];

    if (_selectedReport == 'Custom Report') {
      reportName = _customReportName.trim();

      if (reportName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a custom report name.')),
        );
        return;
      }

      for (final measurement in _customMeasurements) {
        final name = (measurement['name'] ?? '').trim();
        final value = (measurement['value'] ?? '').trim();
        final unit = (measurement['unit'] ?? '').trim();

        // Ignore completely empty measurement rows.
        if (name.isEmpty && value.isEmpty && unit.isEmpty) {
          continue;
        }

        // Every entered row must be complete.
        if (name.isEmpty || value.isEmpty || unit.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Complete the name, value, and unit '
                'for each measurement.',
              ),
            ),
          );
          return;
        }

        final number = double.tryParse(value);

        if (number == null || !number.isFinite) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enter a valid number for $name.')),
          );
          return;
        }

        measurements.add(
          HealthMeasurementModel(name: name, value: number, unit: unit),
        );
      }
    } else {
      reportName = _selectedReport;

      final definitions =
          ReportMeasurementFields.reportFields[_selectedReport]!;

      for (final definition in definitions) {
        final name = definition['name']!;
        final unit = definition['unit']!;
        final enteredValue = _enteredMeasurements[name];

        // Optional measurements can remain empty.
        if (enteredValue == null || enteredValue.isEmpty) {
          continue;
        }

        final number = double.tryParse(enteredValue);

        if (number == null || !number.isFinite || number <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enter a valid positive number for $name.')),
          );
          return;
        }

        measurements.add(
          HealthMeasurementModel(name: name, value: number, unit: unit),
        );
      }
    }

    if (measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement.')),
      );
      return;
    }

    if (measurements.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A report can contain a maximum of 10 measurements.'),
        ),
      );
      return;
    }

    // Create the complete Health Report object.
    final report = HealthReportModel(
      reportType: _selectedReport,
      reportName: reportName,
      reportDate: _reportDate,
      measurements: measurements,
    );

    // Build the review text from the model.
    final measurementSummary = report.measurements
        .map(
          (measurement) =>
              '${measurement.name}: '
              '${measurement.value} '
              '${measurement.unit}',
        )
        .join('\n');

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Report Details'),
          content: SingleChildScrollView(
            child: Text(
              'Report: ${report.reportName}\n'
              'Type: ${report.reportType}\n'
              'Date: $_formattedReportDate\n\n'
              '$measurementSummary\n\n'
              'Please verify every measurement and its unit '
              'against your original laboratory report before saving.',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _saveConfirmedReport(report);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );
  }

  void _onCustomMeasurementsChanged(List<Map<String, String>> measurements) {
    _customMeasurements = measurements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text(
          'Add Health Report',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Report Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose the type of laboratory report '
                    'you want to record.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedReport,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    items: _reportTypes.map((report) {
                      return DropdownMenuItem(
                        value: report,
                        child: Text(report),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != _selectedReport) {
                        setState(() {
                          _selectedReport = value;
                          _enteredMeasurements.clear();
                          _customReportName = '';
                          _customMeasurements = [];
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Date',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _selectReportDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_formattedReportDate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedReport Measurements',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter the values available on your report. '
                    'Leave measurements blank if they were not tested.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_selectedReport == 'Custom Report') ...[
                    TextFormField(
                      initialValue: _customReportName,
                      decoration: const InputDecoration(
                        labelText: 'Custom Report Name',
                        hintText: 'e.g. Vitamin Test',
                        prefixIcon: Icon(Icons.edit_document),
                      ),
                      onChanged: (value) {
                        _customReportName = value;
                      },
                    ),

                    const SizedBox(height: 20),

                    CustomMeasurementFields(
                      key: const ValueKey('custom-measurements'),
                      onMeasurementsChanged: _onCustomMeasurementsChanged,
                    ),
                  ] else
                    ReportMeasurementFields(
                      key: ValueKey(_selectedReport),
                      reportType: _selectedReport,
                      onMeasurementChanged: _onMeasurementChanged,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Enter values exactly as shown on your '
              'laboratory report. Do not estimate missing values.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _validateAndConfirm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(
                _isSaving ? 'Saving Report...' : 'Review Report Details',
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
