import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/weight_trend_service.dart';

class WeightTrendChart extends StatelessWidget {
  final WeightTrendResult result;

  const WeightTrendChart({super.key, required this.result});

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatChange(double? change) {
    if (change == null) {
      return 'Not enough data';
    }

    final sign = change > 0 ? '+' : '';

    return '$sign${change.toStringAsFixed(1)} kg';
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF268C82), size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF086F67),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weight Trend',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Recorded body weight (kg)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),

            if (!result.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 38,
                      color: Color(0xFF268C82),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No weight measurements for this period.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeightTrendPainter(points: result.points),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(result.points.first.date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDate(result.points.last.date),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      label: 'Latest Weight',
                      value: '${result.latestWeight!.toStringAsFixed(1)} kg',
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryTile(
                      label: 'Weight Change',
                      value: _formatChange(result.weightChangeKg),
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                '${result.points.length} recorded day(s) '
                'in the selected period.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

              const SizedBox(height: 6),

              const Text(
                'Only recorded measurements are shown. '
                'Missing dates are not estimated. '
                'Weight changes alone do not determine health.',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  final List<WeightTrendPoint> points;

  const _WeightTrendPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.isEmpty) {
      return;
    }

    const left = 12.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 12.0;

    final chartWidth = math.max(0.0, size.width - left - right);

    final chartHeight = math.max(0.0, size.height - top - bottom);

    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final weights = points.map((point) => point.weightKg).toList();

    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);

    // Add vertical space so the line and dots
    // do not touch the chart boundaries.
    final spread = math.max(1.0, maxWeight - minWeight);

    final margin = spread * 0.2;

    final lowerBound = minWeight - margin;
    final upperBound = maxWeight + margin;
    final valueRange = upperBound - lowerBound;

    final gridPaint = Paint()
      ..color = const Color(0xFFE4ECEA)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;

      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF268C82)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF268C82)
      ..style = PaintingStyle.fill;

    final firstDate = points.first.date;
    final lastDate = points.last.date;

    final totalDays = lastDate.difference(firstDate).inDays;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];

      // Position points by elapsed calendar days,
      // rather than equally spacing all records.
      final x = totalDays == 0
          ? left + chartWidth / 2
          : left +
                chartWidth *
                    point.date.difference(firstDate).inDays /
                    totalDays;

      final normalized = ((point.weightKg - lowerBound) / valueRange).clamp(
        0.0,
        1.0,
      );

      final y = top + chartHeight * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
    }

    if (points.length > 1) {
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) {
      return true;
    }

    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].date != points[i].date ||
          oldDelegate.points[i].weightKg != points[i].weightKg) {
        return true;
      }
    }

    return false;
  }
}
