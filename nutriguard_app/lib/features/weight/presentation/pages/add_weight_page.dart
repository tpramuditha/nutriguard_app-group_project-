import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/weight_log_model.dart';
import '../../data/repositories/weight_log_repository.dart';

class AddWeightPage extends StatefulWidget {
  const AddWeightPage({super.key});

  @override
  State<AddWeightPage> createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  final WeightLogRepository _repository = WeightLogRepository();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select measurement date',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _saveWeight() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());

    if (weight == null || !weight.isFinite) {
      return;
    }

    // Store the selected calendar date at local midnight.
    final measuredAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final weightLog = WeightLogModel(
        id: '',
        weightKg: weight,
        measuredAt: measuredAt,
      );

      await _repository.addWeight(weightLog);

      if (!mounted) return;

      // Return true so Weight History can refresh.
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save weight. Please try again.'),
          backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Add Weight'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
        foregroundColor: const Color(0xFF086F67),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                const Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFFE0F4ED),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      size: 38,
                      color: Color(0xFF086F67),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Log Your Weight',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF086F67),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Record your weight to monitor changes '
                  'over time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 28),

                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Weight Measurement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _weightController,
                          enabled: !_isSaving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'e.g. 65.5',
                            prefixIcon: Icon(Icons.monitor_weight_outlined),
                            suffixText: 'kg',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final weight = double.tryParse(value?.trim() ?? '');

                            if (weight == null || !weight.isFinite) {
                              return 'Enter a valid weight.';
                            }

                            if (weight < 2 || weight > 500) {
                              return 'Weight must be between '
                                  '2 and 500 kg.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Measurement Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _selectDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(_formatDate(_selectedDate)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF086F67),
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveWeight,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Weight'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF086F67),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Weight measurements are recorded '
                  'for personal progress tracking only. '
                  'A weight value alone does not determine '
                  'your health.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
