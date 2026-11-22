import 'package:flutter/material.dart';

import '../../data/models/exercise_log_model.dart';
import '../../data/repositories/exercise_log_repository.dart';

class AddExercisePage extends StatefulWidget {
  final String? initialExerciseName;
  final String? initialExerciseType;
  final int? initialDurationMinutes;
  final bool? initialIsCompleted;

  final DateTime? initialDate;
  final ExerciseLogRepository? repository;

  const AddExercisePage({
    super.key,
    this.initialExerciseName,
    this.initialExerciseType,
    this.initialDurationMinutes,
    this.initialIsCompleted,

    this.initialDate,
    this.repository,
  });

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  late final ExerciseLogRepository _repository;

  static const _exerciseTypes = [
    'Cardio',
    'Strength',
    'Flexibility',
    'Balance',
    'Other',
  ];

  String _selectedType = 'Cardio';
  bool _isCompleted = true;
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? ExerciseLogRepository();

    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    // Automatically populate values when this page

    // Automatically populate values when this page
    // is opened from an exercise recommendation.
    _nameController.text = widget.initialExerciseName ?? '';

    if (widget.initialDurationMinutes != null) {
      _durationController.text = widget.initialDurationMinutes.toString();
    }

    final initialType = widget.initialExerciseType;

    if (initialType != null && _exerciseTypes.contains(initialType)) {
      _selectedType = initialType;
    }

    // Preserve the previous default for manual logging.
    // Recommended sessions start as planned, not completed.
    _isCompleted =
        widget.initialIsCompleted ?? (widget.initialExerciseName == null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _saveExercise() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();

    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final today = DateTime(now.year, now.month, now.day);

    if (_isCompleted && selectedDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A completed exercise cannot have a future date.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final exercise = ExerciseLogModel(
        id: '',
        exerciseName: _nameController.text.trim(),
        exerciseType: _selectedType,
        durationMinutes: int.parse(_durationController.text.trim()),
        isCompleted: _isCompleted,
        // For planned exercises, this is the
        // scheduled date rather than completion time.
        performedAt: selectedDay,
      );

      await _repository.addExercise(exercise);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save exercise. Please try again.'),
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
    final dateLabel =
        '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text('Add Exercise'),
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
                const Text(
                  'Exercise Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF086F67),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Record an activity you completed '
                  'or plan an upcoming exercise.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g. Walking',
                    prefixIcon: Icon(Icons.directions_walk),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an exercise name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedType),
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Type',
                    prefixIcon: Icon(Icons.fitness_center),
                    border: OutlineInputBorder(),
                  ),
                  items: _exerciseTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: 'e.g. 30',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');

                    if (minutes == null) {
                      return 'Enter a valid number of minutes.';
                    }

                    if (minutes < 0 || minutes > 1440) {
                      return 'Duration must be between '
                          '0 and 1440.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Date: $dateLabel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                ),

                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Completed'),
                  subtitle: Text(
                    _isCompleted
                        ? 'This activity has been completed.'
                        : 'This activity is planned.',
                  ),
                  value: _isCompleted,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _isCompleted = value;
                          });
                        },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveExercise,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF086F67),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Track activities at your own pace. '
                  'Consult a healthcare professional if '
                  'you need advice about exercising with '
                  'a medical condition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
