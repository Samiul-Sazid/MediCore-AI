import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class VitalGauge extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final double min;
  final double max;
  final IconData icon;
  final Color activeColor;

  const VitalGauge({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.icon,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final clampedVal = value.clamp(min, max);
    final percent = (clampedVal - min) / (max - min);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _GaugePainter(
                  percent: percent,
                  activeColor: activeColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: activeColor, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    unit == '%' ? value.toStringAsFixed(1) : '${value.toInt()}',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color activeColor;

  _GaugePainter({required this.percent, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percent,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.activeColor != activeColor;
  }
}
