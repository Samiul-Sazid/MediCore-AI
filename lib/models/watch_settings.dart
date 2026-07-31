class WatchSettings {
  final int minHeartRate;
  final int maxHeartRate;
  final double minOxygenLevel;
  final bool alertsEnabled;

  WatchSettings({
    this.minHeartRate = 50,
    this.maxHeartRate = 120,
    this.minOxygenLevel = 92.0,
    this.alertsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'minHeartRate': minHeartRate,
      'maxHeartRate': maxHeartRate,
      'minOxygenLevel': minOxygenLevel,
      'alertsEnabled': alertsEnabled,
    };
  }

  factory WatchSettings.fromMap(Map<dynamic, dynamic> map) {
    return WatchSettings(
      minHeartRate: map['minHeartRate'] ?? 50,
      maxHeartRate: map['maxHeartRate'] ?? 120,
      minOxygenLevel: (map['minOxygenLevel'] ?? 92.0).toDouble(),
      alertsEnabled: map['alertsEnabled'] ?? true,
    );
  }
}
