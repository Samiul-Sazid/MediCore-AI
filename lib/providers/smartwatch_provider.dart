import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/watch_reading.dart';
import '../models/watch_settings.dart';
import '../models/watch_alert.dart';
import '../services/smartwatch_service.dart';
import '../services/hive_service.dart';

class SmartwatchProvider with ChangeNotifier {
  final SmartwatchService _service = SmartwatchService();
  final HiveService _hiveService = HiveService();
  StreamSubscription<WatchReading>? _subscription;

  WatchReading? _currentReading;
  final List<WatchReading> _recentReadings = []; // last 30 readings (60 seconds)
  List<WatchAlert> _alerts = [];
  WatchSettings _settings = WatchSettings();

  WatchReading? get currentReading => _currentReading;
  List<WatchReading> get recentReadings => _recentReadings;
  List<WatchAlert> get alerts => _alerts;
  WatchSettings get settings => _settings;
  bool get isMonitoring => _service.isMonitoring;

  Future<void> init(String userId) async {
    // Load saved settings
    final map = _hiveService.getItem(HiveService.boxWatchSettings, userId);
    if (map != null) {
      _settings = WatchSettings.fromMap(map);
    }

    // Load alert history
    final rawAlerts = _hiveService.getAllItems(HiveService.boxWatchAlerts);
    _alerts = rawAlerts
        .where((m) => m['userId'] == userId)
        .map((m) => WatchAlert.fromMap(m))
        .toList();
    _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    startMonitoring(userId);
  }

  void startMonitoring(String userId) {
    if (_service.isMonitoring) return;

    _service.startMonitoring();
    _subscription = _service.vitalsStream.listen((reading) {
      _currentReading = reading;

      _recentReadings.add(reading);
      if (_recentReadings.length > 30) {
        _recentReadings.removeAt(0);
      }

      // Check alert thresholds
      final alert = _service.checkThresholds(
        reading: reading,
        settings: _settings,
        userId: userId,
      );

      if (alert != null) {
        _alerts.insert(0, alert);
        _hiveService.putItem(HiveService.boxWatchAlerts, alert.id, alert.toMap());
      }

      notifyListeners();
    });
    notifyListeners();
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _service.stopMonitoring();
    notifyListeners();
  }

  void injectAnomaly({int? forcedHR, double? forcedSpO2}) {
    _service.injectAnomaly(forcedHR: forcedHR, forcedSpO2: forcedSpO2);
  }

  Future<void> updateSettings(String userId, WatchSettings newSettings) async {
    _settings = newSettings;
    await _hiveService.putItem(HiveService.boxWatchSettings, userId, newSettings.toMap());
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    _service.dispose();
    super.dispose();
  }
}
