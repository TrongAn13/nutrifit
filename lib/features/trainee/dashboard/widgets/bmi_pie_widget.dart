import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Custom pie-chart widget for displaying BMI value.
///
/// Draws a white circle as the base, overlays a purple arc
/// filling roughly the top-right quadrant, and shows the BMI
/// number on top of the purple slice.
class BmiPieWidget extends StatelessWidget {
  final double bmi;

  const BmiPieWidget({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(90, 90),
        painter: _BmiPiePainter(bmi: bmi),
      ),
    );
  }
}

/// Painter that draws the soft arc and overlays the text dynamically.
class _BmiPiePainter extends CustomPainter {
  final double bmi;

  _BmiPiePainter({required this.bmi});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Circle fills the widget perfectly (radius 45 for 90x90 widget).
    // The purple wedge will overflow this bounds slightly.
    final baseRadius = size.width / 2;

    // Draw the drop shadow for the white circle manually
    final bgPath = Path()..addOval(Rect.fromCircle(center: center, radius: baseRadius));
    canvas.drawShadow(bgPath, Colors.black.withValues(alpha: 0.15), 8.0, true);

    // White filled circle as base
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius, bgPaint);

    // Normalize BMI: using a scale where BMI 20.1 gives ~90 degrees (quarter circle)
    // as shown in the design mockup.
    final progress = (bmi / 80.0).clamp(0.05, 1.0);
    final sweepAngle = 2 * math.pi * progress;

    // Create the wedge path
    final rect = Rect.fromCircle(center: center, radius: baseRadius);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -math.pi / 2, sweepAngle, false)
      ..close();

    final purpleColor = const Color(0xFFCD7ED9);

    // Draw the filled pie wedge
    final fillPaint = Paint()
      ..color = purpleColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw the thick stroke over the wedge to perfectly round all 3 sharp corners 
    // and make it overhang the white background slightly.
    final strokePaint = Paint()
      ..color = purpleColor
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    canvas.drawPath(path, strokePaint);

    // Draw the BMI text in the middle of the drawn arc
    final textStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    // Replace '.' with ',' for Vietnamese locale format "20,1"
    final formattedBmi = bmi.toStringAsFixed(1).replaceAll('.', ',');
    final textSpan = TextSpan(text: formattedBmi, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // The midpoint angle of the purple arc
    final midAngle = -math.pi / 2 + sweepAngle / 2;
    // We place the text slightly inwards
    final textRadius = baseRadius * 0.65; 
    
    final textX = center.dx + textRadius * math.cos(midAngle) - textPainter.width / 2;
    final textY = center.dy + textRadius * math.sin(midAngle) - textPainter.height / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant _BmiPiePainter oldDelegate) =>
      oldDelegate.bmi != bmi;
}
