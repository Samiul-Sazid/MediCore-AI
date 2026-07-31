import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/watch_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/smartwatch_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/vital_gauge.dart';
import '../../widgets/vital_chart.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SmartwatchScreen extends StatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  State<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends State<SmartwatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<SmartwatchProvider>(context, listen: false).init(user.id);
      }
    });
  }

  void _showSettingsModal() {
    final watchProvider = Provider.of<SmartwatchProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    int minHR = watchProvider.settings.minHeartRate;
    int maxHR = watchProvider.settings.maxHeartRate;
    double minSpO2 = watchProvider.settings.minOxygenLevel;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vitals Alert Thresholds', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                  const SizedBox(height: 20),

                  Text('Max Heart Rate Alert ($maxHR bpm)', style: AppTypography.titleSmall),
                  Slider(
                    value: maxHR.toDouble(),
                    min: 90,
                    max: 180,
                    activeColor: AppColors.danger,
                    onChanged: (v) => setModalState(() => maxHR = v.toInt()),
                  ),

                  Text('Min Heart Rate Alert ($minHR bpm)', style: AppTypography.titleSmall),
                  Slider(
                    value: minHR.toDouble(),
                    min: 40,
                    max: 70,
                    activeColor: AppColors.warning,
                    onChanged: (v) => setModalState(() => minHR = v.toInt()),
                  ),

                  Text('Min Oxygen Level Alert (${minSpO2.toStringAsFixed(1)}%)', style: AppTypography.titleSmall),
                  Slider(
                    value: minSpO2,
                    min: 85,
                    max: 95,
                    activeColor: AppColors.info,
                    onChanged: (v) => setModalState(() => minSpO2 = v),
                  ),

                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Save Thresholds',
                    width: double.infinity,
                    onPressed: () async {
                      if (user != null) {
                        await watchProvider.updateSettings(
                          user.id,
                          WatchSettings(
                            minHeartRate: minHR,
                            maxHeartRate: maxHR,
                            minOxygenLevel: minSpO2,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchProvider = Provider.of<SmartwatchProvider>(context);
    final reading = watchProvider.currentReading;
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Smartwatch Telemetry', style: AppTypography.displaySmall),
                    Text('Continuous real-time physiological vitals stream & threshold monitoring', style: AppTypography.bodySmall),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primary),
                      onPressed: _showSettingsModal,
                    ),
                    const SizedBox(width: 8),
                    GradientButton(
                      text: watchProvider.isMonitoring ? 'Stop Monitoring' : 'Start Stream',
                      gradient: watchProvider.isMonitoring ? [AppColors.danger, const Color(0xFF991B1B)] : AppColors.primaryGradient,
                      onPressed: () {
                        if (user != null) {
                          if (watchProvider.isMonitoring) {
                            watchProvider.stopMonitoring();
                          } else {
                            watchProvider.startMonitoring(user.id);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Gauges Row
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  VitalGauge(
                    title: 'Heart Rate',
                    value: (reading?.heartRate ?? 72).toDouble(),
                    unit: 'bpm',
                    min: 40,
                    max: 160,
                    icon: Icons.favorite,
                    activeColor: (reading?.heartRate ?? 72) > watchProvider.settings.maxHeartRate ? AppColors.danger : AppColors.primary,
                  ),
                  VitalGauge(
                    title: 'Blood Oxygen (SpO2)',
                    value: reading?.oxygenLevel ?? 98.2,
                    unit: '%',
                    min: 80,
                    max: 100,
                    icon: Icons.air,
                    activeColor: (reading?.oxygenLevel ?? 98.2) < watchProvider.settings.minOxygenLevel ? AppColors.warning : AppColors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Simulation Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bolt, color: AppColors.danger),
                    label: const Text('Simulate Tachycardia Spike (135 bpm)', style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () => watchProvider.injectAnomaly(forcedHR: 135),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.warning, color: AppColors.warning),
                    label: const Text('Simulate Hypoxia Drop (89% SpO2)', style: TextStyle(color: AppColors.warning)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () => watchProvider.injectAnomaly(forcedSpO2: 89.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rolling Line Chart
            VitalChart(
              readings: watchProvider.recentReadings,
              title: 'Heart Rate Trend (Last 60 Seconds)',
              lineColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Alert Log
            Text('Vitals Alert Log', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            if (watchProvider.alerts.isEmpty)
              Center(child: Text('No telemetry alerts triggered.', style: AppTypography.bodyMedium))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: watchProvider.alerts.length,
                itemBuilder: (context, index) {
                  final alert = watchProvider.alerts[index];
                  final isCritical = alert.severity == 'critical';
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          isCritical ? Icons.error : Icons.warning_amber,
                          color: isCritical ? AppColors.danger : AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert.message,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

