class WatchReading {
  final int heartRate;   // bpm (e.g. 60-120)
  final double oxygenLevel; // SpO2 % (e.g. 95.0-100.0)
  final DateTime timestamp;

  WatchReading({
    required this.heartRate,
    required this.oxygenLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'heartRate': heartRate,
      'oxygenLevel': oxygenLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WatchReading.fromMap(Map<dynamic, dynamic> map) {
    return WatchReading(
      heartRate: map['heartRate'] ?? 72,
      oxygenLevel: (map['oxygenLevel'] ?? 98.0).toDouble(),
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}
