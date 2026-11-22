import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/progress_calculation_service.dart';

class MacroTrendsChart extends StatelessWidget {
  final List<DailyProgressSummary> summaries;

  const MacroTrendsChart({super.key, required this.summaries});

  static const Color _proteinColor = Color(0xFF2588CD);
  static const Color _carbsColor = Color(0xFFE2A12B);
  static const Color _fatColor = Color(0xFF9464CB);

  String _dateLabel(DateTime date, bool weekly) {
    if (!weekly) {
      return '${date.day}/${date.month}';
    }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return days[date.weekday - 1];
  }

  Widget _legend(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No macro trend data available.'),
        ),
      );
    }

    final weekly = summaries.length <= 7;

    final maxValue = summaries.fold<double>(0, (maximum, day) {
      return math.max(
        maximum,
        math.max(day.protein, math.max(day.carbs, day.fat)),
      );
    });

    final chartMax = math.max(1.0, maxValue * 1.15);

    final stepWidth = weekly ? 48.0 : 32.0;

    final chartWidth = math.max(300.0, summaries.length * stepWidth);

    final labelInterval = weekly
        ? 1
        : summaries.length <= 31
        ? 5
        : 15;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macro Trends',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF086F67),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daily logged macronutrients (grams)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Column(
                  children: [
                    SizedBox(
                      height: 170,
                      child: CustomPaint(
                        painter: _MacroLinesPainter(
                          summaries: summaries,
                          maxValue: chartMax,
                          proteinColor: _proteinColor,
                          carbsColor: _carbsColor,
                          fatColor: _fatColor,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var index = 0; index < summaries.length; index++)
                          SizedBox(
                            width: chartWidth / summaries.length,
                            child: Text(
                              index % labelInterval == 0
                                  ? _dateLabel(summaries[index].date, weekly)
                                  : '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _legend('Protein', _proteinColor),
                _legend('Carbs', _carbsColor),
                _legend('Fat', _fatColor),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Days without food logs appear as zero. '
              'This does not confirm zero consumption.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLinesPainter extends CustomPainter {
  final List<DailyProgressSummary> summaries;
  final double maxValue;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;

  const _MacroLinesPainter({
    required this.summaries,
    required this.maxValue,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (summaries.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5ECEA)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawSeries(
      double Function(DailyProgressSummary) getValue,
      Color color,
    ) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();

      final pointWidth = size.width / summaries.length;

      for (var i = 0; i < summaries.length; i++) {
        final value = getValue(summaries[i]);

        final x = pointWidth * (i + 0.5);

        final normalized = (value / maxValue).clamp(0.0, 1.0);

        final y = size.height * (1 - normalized);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        if (summaries.length <= 31) {
          canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
        }
      }

      canvas.drawPath(path, linePaint);
    }

    drawSeries((day) => day.protein, proteinColor);
    drawSeries((day) => day.carbs, carbsColor);
    drawSeries((day) => day.fat, fatColor);
  }

  @override
  bool shouldRepaint(covariant _MacroLinesPainter oldDelegate) {
    return oldDelegate.summaries != summaries ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.proteinColor != proteinColor ||
        oldDelegate.carbsColor != carbsColor ||
        oldDelegate.fatColor != fatColor;
  }
}
