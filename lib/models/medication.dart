class Medication {
  final String id;
  final String userId;
  final String drugName;
  final String dosage;
  final String frequency;
  final String whenToTake;
  final String prescribedBy;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'active' | 'stopped'
  final String stopReason;
  final String notes;
  final List<DateTime> takenDates; // ISO timestamps of doses taken

  Medication({
    required this.id,
    required this.userId,
    required this.drugName,
    required this.dosage,
    required this.frequency,
    this.whenToTake = 'With meals',
    this.prescribedBy = '',
    required this.startDate,
    this.endDate,
    this.status = 'active',
    this.stopReason = '',
    this.notes = '',
    this.takenDates = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';

  bool takenToday() {
    final now = DateTime.now();
    return takenDates.any((d) =>
      d.year == now.year && d.month == now.month && d.day == now.day
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'drugName': drugName,
      'dosage': dosage,
      'frequency': frequency,
      'whenToTake': whenToTake,
      'prescribedBy': prescribedBy,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'stopReason': stopReason,
      'notes': notes,
      'takenDates': takenDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory Medication.fromMap(Map<dynamic, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      drugName: map['drugName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      whenToTake: map['whenToTake'] ?? 'With meals',
      prescribedBy: map['prescribedBy'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      status: map['status'] ?? 'active',
      stopReason: map['stopReason'] ?? '',
      notes: map['notes'] ?? '',
      takenDates: (map['takenDates'] as List? ?? [])
          .map((d) => DateTime.parse(d.toString()))
          .toList(),
    );
  }
}
