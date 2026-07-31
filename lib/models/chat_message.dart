class ChatMessage {
  final String id;
  final String sessionId;
  final String userId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isEmergency;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isEmergency = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isEmergency': isEmergency,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      isEmergency: map['isEmergency'] ?? false,
    );
  }
}
