import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:finport/models/expense.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. PREMIUM ANIMATED DONUT CHART
// ==========================================

class PremiumDonutChart extends StatefulWidget {
  final Map<String, double> categoryData;
  final double height;

  const PremiumDonutChart({
    super.key,
    required this.categoryData,
    this.height = 200,
  });

  @override
  State<PremiumDonutChart> createState() => _PremiumDonutChartState();
}

class _PremiumDonutChartState extends State<PremiumDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PremiumDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryData.values.fold(0.0, (sum, val) => sum + val);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.height, widget.height),
                  painter: _DonutChartPainter(
                    categoryData: widget.categoryData,
                    total: total,
                    animationValue: _animation.value,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          // Center Typography Display (Total Spending)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL SPENT',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${NumberFormat('#,##,###').format(total)}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryData;
  final double total;
  final double animationValue;
  final bool isDark;

  _DonutChartPainter({
    required this.categoryData,
    required this.total,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total == 0) {
      // Draw empty placeholder ring with adaptive theme colors
      final paint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26.0;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -math.pi / 2; // Start drawing from 12 o'clock

    for (var entry in categoryData.entries) {
      final category = ExpenseCategory.fromName(entry.key);
      final value = entry.value;
      final sweepAngle = (value / total) * 2 * math.pi * animationValue;

      if (sweepAngle > 0.001) {
        final paint = Paint()
          ..color = category.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24.0
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          rect,
          startAngle + 0.05,
          sweepAngle - 0.1 > 0 ? sweepAngle - 0.1 : sweepAngle,
          false,
          paint,
        );
      }

      startAngle += (value / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.categoryData != categoryData ||
        oldDelegate.isDark != isDark;
  }
}

// ==========================================
// 2. PREMIUM SMOOTH BEZIER TREND CHART
// ==========================================

class PremiumBezierChart extends StatefulWidget {
  final List<double> dailySpends;
  final double height;

  const PremiumBezierChart({
    super.key,
    required this.dailySpends,
    this.height = 200,
  });

  @override
  State<PremiumBezierChart> createState() => _PremiumBezierChartState();
}

class _PremiumBezierChartState extends State<PremiumBezierChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PremiumBezierChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _BezierChartPainter(
              dailySpends: widget.dailySpends,
              animationValue: _animation.value,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }
}

class _BezierChartPainter extends CustomPainter {
  final List<double> dailySpends;
  final double animationValue;
  final bool isDark;

  _BezierChartPainter({
    required this.dailySpends,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySpends.isEmpty) return;

    final double maxVal = dailySpends.reduce(math.max);
    final double padding = 20.0;
    final double chartHeight = size.height - padding * 2;
    final double chartWidth = size.width;

    // Background dashed helper lines (adaptive tint)
    final linePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, padding), Offset(chartWidth, padding), linePaint);
    canvas.drawLine(Offset(0, padding + chartHeight / 2),
        Offset(chartWidth, padding + chartHeight / 2), linePaint);
    canvas.drawLine(Offset(0, padding + chartHeight),
        Offset(chartWidth, padding + chartHeight), linePaint);

    if (maxVal <= 0) {
      // Draw flat baseline if there is no spending data
      final paint = Paint()
        ..color = const Color(0xFF6C5DD3).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawLine(
        Offset(0, padding + chartHeight),
        Offset(chartWidth, padding + chartHeight),
        paint,
      );
      return;
    }

    final double segmentWidth = chartWidth / (dailySpends.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < dailySpends.length; i++) {
      final x = i * segmentWidth;
      final relativeHeight = (dailySpends[i] / maxVal) * chartHeight * animationValue;
      final y = padding + chartHeight - relativeHeight;
      points.add(Offset(x, y));
    }

    // Generate smoothed Bezier Splines
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPointX = p1.dx + (p2.dx - p1.dx) / 2;
      
      path.cubicTo(
        controlPointX,
        p1.dy,
        controlPointX,
        p2.dy,
        p2.dx,
        p2.dy,
      );
    }

    // Paint the bottom gradient fill shape
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, padding + chartHeight)
      ..lineTo(points.first.dx, padding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6C5DD3).withOpacity(0.35),
          const Color(0xFF6C5DD3).withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTWH(0, padding, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint the elegant glowing line stroke itself
    final strokePaint = Paint()
      ..color = const Color(0xFF6C5DD3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw glowing circles at critical hot points (local maximums or latest active point)
    final latestPoint = points.last;
    final glowPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;

    final glowBorder = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF1C1C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(latestPoint, 6.0, glowPaint);
    canvas.drawCircle(latestPoint, 6.0, glowBorder);
  }

  @override
  bool shouldRepaint(covariant _BezierChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.dailySpends != dailySpends ||
        oldDelegate.isDark != isDark;
  }
}
