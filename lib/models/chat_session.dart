class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<dynamic, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Health Consultation',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
