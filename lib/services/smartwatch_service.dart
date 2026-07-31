import 'dart:async';
import 'dart:math';
import '../models/watch_reading.dart';
import '../models/watch_settings.dart';
import '../models/watch_alert.dart';

class SmartwatchService {
  StreamController<WatchReading>? _controller;
  Timer? _timer;
  final Random _random = Random();

  int _currentHR = 75;
  double _currentSpO2 = 98.2;

  Stream<WatchReading> get vitalsStream {
    _controller ??= StreamController<WatchReading>.broadcast();
    return _controller!.stream;
  }

  bool get isMonitoring => _timer != null && _timer!.isActive;

  void startMonitoring() {
    if (isMonitoring) return;

    _timer = Timer.periodic(const Duration(seconds: 2), (t) {
      // Simulate physiological drift
      final hrDelta = _random.nextInt(5) - 2; // -2 to +2
      _currentHR = (_currentHR + hrDelta).clamp(58, 128);

      final spo2Delta = (_random.nextDouble() * 0.4) - 0.2; // -0.2 to +0.2
      _currentSpO2 = (_currentSpO2 + spo2Delta).clamp(90.0, 100.0);

      final reading = WatchReading(
        heartRate: _currentHR,
        oxygenLevel: double.parse(_currentSpO2.toStringAsFixed(1)),
        timestamp: DateTime.now(),
      );

      _controller?.add(reading);
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  void injectAnomaly({int? forcedHR, double? forcedSpO2}) {
    if (forcedHR != null) _currentHR = forcedHR;
    if (forcedSpO2 != null) _currentSpO2 = forcedSpO2;
  }

  WatchAlert? checkThresholds({
    required WatchReading reading,
    required WatchSettings settings,
    required String userId,
  }) {
    if (!settings.alertsEnabled) return null;

    if (reading.heartRate > settings.maxHeartRate) {
      return WatchAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        severity: 'critical',
        message: 'Elevated Tachycardia Warning: Heart rate reached ${reading.heartRate} bpm (Threshold: ${settings.maxHeartRate} bpm).',
        heartRate: reading.heartRate,
        oxygenLevel: reading.oxygenLevel,
        timestamp: reading.timestamp,
      );
    }

    if (reading.heartRate < settings.minHeartRate) {
      return WatchAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        severity: 'warning',
        message: 'Bradycardia Alert: Heart rate dropped to ${reading.heartRate} bpm (Threshold: ${settings.minHeartRate} bpm).',
        heartRate: reading.heartRate,
        oxygenLevel: reading.oxygenLevel,
        timestamp: reading.timestamp,
      );
    }

    if (reading.oxygenLevel < settings.minOxygenLevel) {
      return WatchAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        severity: 'critical',
        message: 'Hypoxia Alert: Blood oxygen level fell to ${reading.oxygenLevel}% (Threshold: ${settings.minOxygenLevel}%).',
        heartRate: reading.heartRate,
        oxygenLevel: reading.oxygenLevel,
        timestamp: reading.timestamp,
      );
    }

    return null;
  }

  void dispose() {
    stopMonitoring();
    _controller?.close();
  }
}
