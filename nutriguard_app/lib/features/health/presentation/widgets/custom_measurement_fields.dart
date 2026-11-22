import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CustomMeasurementFields extends StatefulWidget {
  final void Function(List<Map<String, String>> measurements)
  onMeasurementsChanged;

  const CustomMeasurementFields({
    super.key,
    required this.onMeasurementsChanged,
  });

  @override
  State<CustomMeasurementFields> createState() =>
      _CustomMeasurementFieldsState();
}

class _CustomMeasurementFieldsState extends State<CustomMeasurementFields> {
  int _nextId = 1;

  final List<Map<String, dynamic>> _measurements = [
    {'id': 0, 'name': '', 'value': '', 'unit': ''},
  ];

  void _notifyParent() {
    final result = _measurements.map((measurement) {
      return <String, String>{
        'name': measurement['name'] as String,
        'value': measurement['value'] as String,
        'unit': measurement['unit'] as String,
      };
    }).toList();

    widget.onMeasurementsChanged(result);
  }

  void _updateMeasurement(int id, String field, String value) {
    final index = _measurements.indexWhere(
      (measurement) => measurement['id'] == id,
    );

    if (index == -1) return;

    _measurements[index][field] = value;
    _notifyParent();
  }

  void _addMeasurement() {
    if (_measurements.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A report can contain a maximum of 10 measurements.'),
        ),
      );
      return;
    }

    setState(() {
      _measurements.add({'id': _nextId++, 'name': '', 'value': '', 'unit': ''});
    });

    _notifyParent();
  }

  void _removeMeasurement(int id) {
    if (_measurements.length <= 1) return;

    setState(() {
      _measurements.removeWhere((measurement) => measurement['id'] == id);
    });

    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Measurements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Enter the name, value, and unit '
          'shown on your laboratory report.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        for (int index = 0; index < _measurements.length; index++)
          Padding(
            key: ValueKey(_measurements[index]['id']),
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Measurement ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      if (_measurements.length > 1)
                        IconButton(
                          onPressed: () {
                            _removeMeasurement(
                              _measurements[index]['id'] as int,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _measurements[index]['name'] as String,
                    decoration: const InputDecoration(
                      labelText: 'Measurement Name',
                      hintText: 'e.g. Vitamin D',
                    ),
                    onChanged: (value) {
                      _updateMeasurement(
                        _measurements[index]['id'] as int,
                        'name',
                        value,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _measurements[index]['value'] as String,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Value',
                      hintText: 'e.g. 35',
                    ),
                    onChanged: (value) {
                      _updateMeasurement(
                        _measurements[index]['id'] as int,
                        'value',
                        value,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: _measurements[index]['unit'] as String,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'e.g. ng/mL',
                    ),
                    onChanged: (value) {
                      _updateMeasurement(
                        _measurements[index]['id'] as int,
                        'unit',
                        value,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

        OutlinedButton.icon(
          onPressed: _addMeasurement,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Measurement'),
        ),
      ],
    );
  }
}
