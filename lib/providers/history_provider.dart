import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/health_event.dart';
import '../services/hive_service.dart';

class HistoryProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final Uuid _uuid = const Uuid();

  List<HealthEvent> _events = [];

  List<HealthEvent> get events => _events;

  Future<void> loadEvents(String userId) async {
    final raw = _hiveService.getAllItems(HiveService.boxHealthEvents);
    _events = raw
        .where((map) => map['userId'] == userId)
        .map((map) => HealthEvent.fromMap(map))
        .toList();
    _events.sort((a, b) => b.date.compareTo(a.date));

    // If empty, populate initial sample history
    if (_events.isEmpty) {
      await _populateSampleHistory(userId);
    }
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
    final event = HealthEvent(
      id: _uuid.v4(),
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
    await _hiveService.deleteItem(HiveService.boxHealthEvents, eventId);
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }

  Future<void> _populateSampleHistory(String userId) async {
    final now = DateTime.now();
    final samples = [
      HealthEvent(
        id: _uuid.v4(),
        userId: userId,
        type: 'medication',
        title: 'Medication Started',
        description: 'Began Lisinopril 10mg prescribed by Dr. Elena Rostova.',
        date: now.subtract(const Duration(days: 2)),
      ),
      HealthEvent(
        id: _uuid.v4(),
        userId: userId,
        type: 'scan',
        title: 'Prescription Scanned',
        description: 'Successfully scanned Lisinopril prescription label.',
        date: now.subtract(const Duration(days: 3)),
      ),
      HealthEvent(
        id: _uuid.v4(),
        userId: userId,
        type: 'vitals',
        title: 'Smartwatch Vitals Monitored',
        description: 'Average Heart Rate 72 bpm, SpO2 98.5%.',
        date: now.subtract(const Duration(days: 5)),
      ),
      HealthEvent(
        id: _uuid.v4(),
        userId: userId,
        type: 'appointment',
        title: 'Annual Physical Checkup',
        description: 'Completed consultation with Dr. Aris Thorne at Community Family Care.',
        date: now.subtract(const Duration(days: 14)),
      ),
    ];

    for (var s in samples) {
      await _hiveService.putItem(HiveService.boxHealthEvents, s.id, s.toMap());
      _events.add(s);
    }
  }
}
