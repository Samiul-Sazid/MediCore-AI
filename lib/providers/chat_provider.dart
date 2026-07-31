import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../models/watch_reading.dart';
import '../services/claude_service.dart';
import '../services/hive_service.dart';

class ChatProvider with ChangeNotifier {
  final ClaudeService _claudeService = ClaudeService();
  final HiveService _hiveService = HiveService();
  final Uuid _uuid = const Uuid();

  ChatSession? _currentSession;
  List<ChatSession> _sessions = [];
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  ChatSession? get currentSession => _currentSession;
  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get hasApiKey => _claudeService.getApiKey() != null;

  Future<void> loadUserSessions(String userId) async {
    final rawSessions = _hiveService.getAllItems(HiveService.boxChatSessions);
    _sessions = rawSessions
        .where((map) => map['userId'] == userId)
        .map((map) => ChatSession.fromMap(map))
        .toList();
    _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_sessions.isNotEmpty) {
      await selectSession(_sessions.first.id, userId);
    } else {
      await createNewSession(userId);
    }
  }

  Future<ChatSession> createNewSession(String userId, {String title = 'Health Consultation'}) async {
    final session = ChatSession(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      createdAt: DateTime.now(),
    );

    await _hiveService.putItem(HiveService.boxChatSessions, session.id, session.toMap());
    _sessions.insert(0, session);
    _currentSession = session;
    _messages = [];

    // Add welcoming message
    final welcome = ChatMessage(
      id: _uuid.v4(),
      sessionId: session.id,
      userId: userId,
      role: 'assistant',
      content: '''Hello! I'm your MediCore AI Health Advisor. How can I assist with your wellness today?

You can ask me about medication guidance, symptom evaluation, diet recommendations, or review of your latest health records.

*(Disclaimer: I provide health insights based on clinical guidelines, but always consult a licensed doctor for diagnosis.)*''',
      timestamp: DateTime.now(),
    );

    await _hiveService.putItem(HiveService.boxChatMessages, welcome.id, welcome.toMap());
    _messages.add(welcome);

    notifyListeners();
    return session;
  }

  Future<void> selectSession(String sessionId, String userId) async {
    final sessionMap = _hiveService.getItem(HiveService.boxChatSessions, sessionId);
    if (sessionMap != null) {
      _currentSession = ChatSession.fromMap(sessionMap);
      
      final rawMessages = _hiveService.getAllItems(HiveService.boxChatMessages);
      _messages = rawMessages
          .where((map) => map['sessionId'] == sessionId)
          .map((map) => ChatMessage.fromMap(map))
          .toList();
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String userText,
    required String userId,
    required UserProfile profile,
    required List<Medication> activeMeds,
    WatchReading? currentVitals,
  }) async {
    if (userText.trim().isEmpty) return;
    if (_currentSession == null) {
      await createNewSession(userId);
    }

    final sessionId = _currentSession!.id;

    // 1. Save and display user message immediately
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      userId: userId,
      role: 'user',
      content: userText.trim(),
      timestamp: DateTime.now(),
    );

    await _hiveService.putItem(HiveService.boxChatMessages, userMsg.id, userMsg.toMap());
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // 2. Prepare message history for Claude API
    final historyPayload = _messages.take(_messages.length - 1).map((m) => {
      'role': m.role,
      'content': m.content,
    }).toList();

    try {
      final replyText = await _claudeService.sendMessage(
        userPrompt: userText.trim(),
        messageHistory: historyPayload,
        profile: profile,
        activeMedications: activeMeds,
        currentVitals: currentVitals,
      );

      final isEmergency = replyText.contains('⚠ THIS MAY BE AN EMERGENCY');

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        userId: userId,
        role: 'assistant',
        content: replyText,
        timestamp: DateTime.now(),
        isEmergency: isEmergency,
      );

      await _hiveService.putItem(HiveService.boxChatMessages, aiMsg.id, aiMsg.toMap());
      _messages.add(aiMsg);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        userId: userId,
        role: 'assistant',
        content: 'I apologize, an error occurred while processing your request: ${e.toString().replaceAll("Exception: ", "")}',
        timestamp: DateTime.now(),
      );
      await _hiveService.putItem(HiveService.boxChatMessages, errorMsg.id, errorMsg.toMap());
      _messages.add(errorMsg);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId, String userId) async {
    await _hiveService.deleteItem(HiveService.boxChatSessions, sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);

    // Delete associated messages
    final rawMessages = _hiveService.getAllItems(HiveService.boxChatMessages);
    for (var map in rawMessages) {
      if (map['sessionId'] == sessionId) {
        await _hiveService.deleteItem(HiveService.boxChatMessages, map['id']);
      }
    }

    if (_currentSession?.id == sessionId) {
      if (_sessions.isNotEmpty) {
        await selectSession(_sessions.first.id, userId);
      } else {
        await createNewSession(userId);
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> saveApiKey(String key) async {
    await _claudeService.saveApiKey(key);
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _claudeService.clearApiKey();
    notifyListeners();
  }
}
