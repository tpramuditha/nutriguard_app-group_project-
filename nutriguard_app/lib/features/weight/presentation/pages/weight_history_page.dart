import 'package:flutter/material.dart';

import '../../data/models/weight_log_model.dart';
import '../../data/repositories/weight_log_repository.dart';
import 'add_weight_page.dart';

class WeightHistoryPage extends StatefulWidget {
  const WeightHistoryPage({super.key});

  @override
  State<WeightHistoryPage> createState() => _WeightHistoryPageState();
}

class _WeightHistoryPageState extends State<WeightHistoryPage> {
  final WeightLogRepository _repository = WeightLogRepository();

  late Future<List<WeightLogModel>> _weightsFuture;

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  void _loadWeights() {
    _weightsFuture = _repository.getWeightLogs();
  }

  Future<void> _refreshWeights() async {
    setState(_loadWeights);

    try {
      await _weightsFuture;
    } catch (_) {
      // FutureBuilder handles loading errors.
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddWeight() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddWeightPage()),
    );

    if (!mounted) return;

    if (saved == true) {
      await _refreshWeights();
    }
  }

  Future<void> _editWeight(WeightLogModel weight) async {
    final controller = TextEditingController(text: weight.weightKg.toString());

    double? updatedWeight;

    try {
      updatedWeight = await showDialog<double>(
        context: context,
        builder: (dialogContext) {
          final formKey = GlobalKey<FormState>();

          return AlertDialog(
            title: const Text('Edit Weight'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Measurement date: '
                    '${_formatDate(weight.measuredAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');

                      if (number == null || !number.isFinite) {
                        return 'Enter a valid weight.';
                      }

                      if (number < 2 || number > 500) {
                        return 'Weight must be between '
                            '2 and 500 kg.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  final value = double.parse(controller.text.trim());

                  Navigator.pop(dialogContext, value);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      // Defer disposal until the dialog's exit animation
      // has finished, avoiding controller use during exit.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      controller.dispose();
    }

    if (!mounted || updatedWeight == null) return;

    try {
      await _repository.updateWeight(weight.copyWith(weightKg: updatedWeight));

      if (!mounted) return;

      _showMessage('Weight updated successfully.');
      await _refreshWeights();
    } catch (_) {
      _showMessage('Unable to update weight. Please try again.');
    }
  }

  Future<void> _deleteWeight(WeightLogModel weight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Weight?'),
          content: Text(
            'Delete the ${weight.weightKg.toStringAsFixed(1)} kg '
            'measurement from '
            '${_formatDate(weight.measuredAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteWeight(weight.id);

      if (!mounted) return;

      _showMessage('Weight deleted successfully.');
      await _refreshWeights();
    } catch (_) {
      _showMessage('Unable to delete weight. Please try again.');
    }
  }

  Widget _weightCard(WeightLogModel weight) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE0F4ED),
              child: Icon(
                Icons.monitor_weight_outlined,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weight.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF086F67),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(weight.measuredAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit weight',
              onPressed: () => _editWeight(weight),
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF086F67)),
            ),
            IconButton(
              tooltip: 'Delete weight',
              onPressed: () => _deleteWeight(weight),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Weight History'),
        backgroundColor: const Color(0xFFF5FAFC),
        foregroundColor: const Color(0xFF086F67),
        actions: [
          IconButton(
            tooltip: 'Refresh weights',
            onPressed: _refreshWeights,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddWeight,
        icon: const Icon(Icons.add),
        label: const Text('Add Weight'),
      ),
      body: FutureBuilder<List<WeightLogModel>>(
        future: _weightsFuture,
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
                    const Text(
                      'Unable to load weight history.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshWeights,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final weights = snapshot.data ?? <WeightLogModel>[];

          if (weights.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monitor_weight_outlined,
                      size: 48,
                      color: Color(0xFF086F67),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No weight measurements recorded yet.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a measurement to start '
                      'tracking your weight.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openAddWeight,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Weight'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshWeights,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: weights.length,
              itemBuilder: (context, index) {
                return _weightCard(weights[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
