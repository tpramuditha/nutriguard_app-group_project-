import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/health_marker_trend_service.dart';

class HealthMarkerTrendChart extends StatelessWidget {
  final String title;
  final List<HealthMarkerTrendPoint> points;
  final Color lineColor;

  const HealthMarkerTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.lineColor = const Color(0xFF268C82),
  });

  String _monthLabel(String month) {
    final parts = month.split('-');

    if (parts.length != 2) return month;

    final number = int.tryParse(parts[1]);

    const monthNames = [
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

    if (number == null || number < 1 || number > 12) {
      return month;
    }

    return '${monthNames[number - 1]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    // Avoid mixing different measurement names or units
    // in a single chart.
    final isConsistent =
        points.isEmpty ||
        points.every(
          (point) =>
              point.measurementName == points.first.measurementName &&
              point.unit == points.first.unit,
        );

    if (!isConsistent) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$title: incompatible measurement types or units.'),
        ),
      );
    }

    final sortedPoints = [...points]
      ..sort((a, b) => a.month.compareTo(b.month));

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(height: 6),
            if (sortedPoints.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Center(
                  child: Text(
                    'No health marker records available.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Text(
                '${sortedPoints.first.measurementName} '
                '(${sortedPoints.first.unit})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HealthMarkerPainter(
                    points: sortedPoints,
                    lineColor: lineColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final point in sortedPoints)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${_monthLabel(point.month)}: '
                        '${point.value.toStringAsFixed(1)} '
                        '${point.unit}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Only recorded measurements are shown. '
                'Missing months are not estimated.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HealthMarkerPainter extends CustomPainter {
  final List<HealthMarkerTrendPoint> points;
  final Color lineColor;

  const _HealthMarkerPainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.isEmpty) return;

    const padding = 12.0;

    final width = math.max(0.0, size.width - padding * 2);
    final height = math.max(0.0, size.height - padding * 2);

    if (width == 0 || height == 0) return;

    final values = points.map((point) => point.value).toList();

    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);

    final spread = math.max(1.0, maximum - minimum);
    final margin = spread * 0.15;

    final lowerBound = minimum - margin;
    final upperBound = maximum + margin;
    final range = upperBound - lowerBound;

    final gridPaint = Paint()
      ..color = const Color(0xFFE4ECEA)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = padding + height * i / 4;

      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + width, y),
        gridPaint,
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? padding + width / 2
          : padding + width * i / (points.length - 1);

      final normalized = ((points[i].value - lowerBound) / range).clamp(
        0.0,
        1.0,
      );

      final y = padding + height * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    if (points.length > 1) {
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthMarkerPainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.points.length != points.length) {
      return true;
    }

    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].month != points[i].month ||
          oldDelegate.points[i].value != points[i].value ||
          oldDelegate.points[i].unit != points[i].unit ||
          oldDelegate.points[i].measurementName != points[i].measurementName) {
        return true;
      }
    }

    return false;
  }
}
