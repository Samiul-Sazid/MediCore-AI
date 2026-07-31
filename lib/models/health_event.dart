class HealthEvent {
  final String id;
  final String userId;
  final String type; // 'medication' | 'scan' | 'vitals' | 'appointment' | 'document' | 'custom'
  final String title;
  final String description;
  final DateTime date;
  final Map<String, dynamic> metadata;

  HealthEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory HealthEvent.fromMap(Map<dynamic, dynamic> map) {
    return HealthEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'custom',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
