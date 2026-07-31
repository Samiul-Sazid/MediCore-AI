import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/watch_reading.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class VitalChart extends StatelessWidget {
  final List<WatchReading> readings;
  final String title;
  final Color lineColor;

  const VitalChart({
    super.key,
    required this.readings,
    required this.title,
    this.lineColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: 180,
        child: GlassCard(
          child: Center(
            child: Text('Waiting for live telemetry stream...', style: AppTypography.bodySmall),
          ),
        ),
      );
    }

    final spots = readings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.heartRate.toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleSmall),
              Text(
                '${readings.last.heartRate} bpm',
                style: AppTypography.labelLarge.copyWith(color: lineColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (readings.length - 1).toDouble().clamp(1.0, 30.0),
                minY: 40,
                maxY: 140,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
