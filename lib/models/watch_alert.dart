class WatchAlert {
  final String id;
  final String userId;
  final String severity; // 'warning' | 'critical'
  final String message;
  final int heartRate;
  final double oxygenLevel;
  final DateTime timestamp;

  WatchAlert({
    required this.id,
    required this.userId,
    required this.severity,
    required this.message,
    required this.heartRate,
    required this.oxygenLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'severity': severity,
      'message': message,
      'heartRate': heartRate,
      'oxygenLevel': oxygenLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WatchAlert.fromMap(Map<dynamic, dynamic> map) {
    return WatchAlert(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      severity: map['severity'] ?? 'warning',
      message: map['message'] ?? '',
      heartRate: map['heartRate'] ?? 0,
      oxygenLevel: (map['oxygenLevel'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}
