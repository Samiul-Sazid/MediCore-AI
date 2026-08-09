import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/health_event.dart';
import '../services/hive_service.dart';
import '../services/api_client.dart';

class HistoryProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();
  final Uuid _uuid = const Uuid();

  List<HealthEvent> _events = [];

  List<HealthEvent> get events => _events;

  Future<void> loadEvents(String userId) async {
    // Try loading from backend API
    try {
      final data = await _api.get('/history/');
      if (data != null && data is List) {
        for (var eventData in data) {
          final event = HealthEvent(
            id: eventData['id'].toString(),
            userId: userId,
            type: eventData['type'] ?? 'system',
            title: eventData['title'] ?? '',
            description: eventData['description'] ?? '',
            date: eventData['created_at'] != null
                ? DateTime.tryParse(eventData['created_at']) ?? DateTime.now()
                : DateTime.now(),
            metadata: eventData['metadata'] is Map
                ? Map<String, dynamic>.from(eventData['metadata'])
                : {},
          );
          await _hiveService.putItem(HiveService.boxHealthEvents, event.id, event.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load health events from backend: $e');
    }

    // Load from Hive (includes backend-synced + local-only events)
    final raw = _hiveService.getAllItems(HiveService.boxHealthEvents);
    _events = raw
        .where((map) => map['userId'] == userId)
        .map((map) => HealthEvent.fromMap(map))
        .toList();
    _events.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<HealthEvent> addEvent({
    required String userId,
    required String type,
    required String title,
    required String description,
    DateTime? date,
    Map<String, dynamic> metadata = const {},
  }) async {
    String eventId = _uuid.v4();

    // Push to backend
    try {
      final response = await _api.post('/history/', {
        'type': type,
        'title': title,
        'description': description,
        'metadata': metadata,
      });
      if (response != null && response['id'] != null) {
        eventId = response['id'].toString();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to push health event to backend: $e');
    }

    final event = HealthEvent(
      id: eventId,
      userId: userId,
      type: type,
      title: title,
      description: description,
      date: date ?? DateTime.now(),
      metadata: metadata,
    );

    await _hiveService.putItem(HiveService.boxHealthEvents, event.id, event.toMap());
    _events.insert(0, event);
    notifyListeners();
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    // Push to backend
    try {
      await _api.delete('/history/$eventId');
    } catch (e) {
      if (kDebugMode) print('Failed to delete health event from backend: $e');
    }

    await _hiveService.deleteItem(HiveService.boxHealthEvents, eventId);
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }
}
