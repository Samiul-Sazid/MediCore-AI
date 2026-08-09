import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../services/hive_service.dart';
import '../services/interaction_service.dart';
import '../services/api_client.dart';

class MedicationProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final InteractionService _interactionService = InteractionService();
  final ApiClient _api = ApiClient();
  final Uuid _uuid = const Uuid();

  List<Medication> _medications = [];

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => _medications.where((m) => m.isActive).toList();
  List<Medication> get stoppedMedications => _medications.where((m) => !m.isActive).toList();

  Future<void> loadMedications(String userId) async {
    try {
      final data = await _api.get('/prescription/medications');
      if (data != null && data is List) {
        // Sync API data into Hive
        for (var medData in data) {
          final med = Medication(
            id: medData['id'].toString(),
            userId: userId,
            drugName: medData['drug_name'] ?? 'Unknown',
            dosage: medData['dosage'] ?? '',
            frequency: medData['frequency'] ?? '',
            whenToTake: medData['when_to_take'] ?? 'Follow prescription',
            prescribedBy: medData['prescribed_by'] ?? '',
            startDate: medData['start_date'] != null
                ? DateTime.tryParse(medData['start_date']) ?? DateTime.now()
                : DateTime.now(),
            endDate: medData['end_date'] != null
                ? DateTime.tryParse(medData['end_date'])
                : null,
            status: medData['status'] ?? 'active',
            stopReason: medData['stop_reason'] ?? '',
            notes: medData['notes'] ?? medData['duration'] ?? '',
          );
          await _hiveService.putItem(HiveService.boxMedications, med.id, med.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load medications from API: $e');
    }

    final raw = _hiveService.getAllItems(HiveService.boxMedications);
    _medications = raw
        .where((map) => map['userId'] == userId)
        .map((map) => Medication.fromMap(map))
        .toList();
    _medications.sort((a, b) => b.startDate.compareTo(a.startDate));
    notifyListeners();
  }

  Future<Medication> addMedication({
    required String userId,
    required String drugName,
    required String dosage,
    required String frequency,
    required String whenToTake,
    String prescribedBy = '',
    DateTime? startDate,
    String notes = '',
  }) async {
    String medId = _uuid.v4();

    // Push to backend first to get server-assigned ID
    try {
      final response = await _api.post('/prescription/medications', {
        'drug_name': drugName.trim(),
        'dosage': dosage.trim(),
        'frequency': frequency.trim(),
        'when_to_take': whenToTake.trim(),
        'prescribed_by': prescribedBy.trim(),
        'notes': notes.trim(),
        'duration': notes.trim(),
      });
      if (response != null && response['id'] != null) {
        medId = response['id'].toString();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to push medication to backend: $e');
    }

    final med = Medication(
      id: medId,
      userId: userId,
      drugName: drugName.trim(),
      dosage: dosage.trim(),
      frequency: frequency.trim(),
      whenToTake: whenToTake,
      prescribedBy: prescribedBy.trim(),
      startDate: startDate ?? DateTime.now(),
      status: 'active',
      notes: notes.trim(),
    );

    await _hiveService.putItem(HiveService.boxMedications, med.id, med.toMap());
    _medications.insert(0, med);

    // Create a health history event
    _createHistoryEvent(
      type: 'medication',
      title: 'Medication Started',
      description: 'Began ${drugName.trim()} ${dosage.trim()} — ${frequency.trim()}.',
    );

    notifyListeners();
    return med;
  }

  Future<void> toggleTakenToday(String medicationId) async {
    final idx = _medications.indexWhere((m) => m.id == medicationId);
    if (idx == -1) return;

    final old = _medications[idx];
    final now = DateTime.now();
    final List<DateTime> updatedTaken = List.from(old.takenDates);

    if (old.takenToday()) {
      // Remove today's dose
      updatedTaken.removeWhere((d) => d.year == now.year && d.month == now.month && d.day == now.day);
    } else {
      // Add today's dose
      updatedTaken.add(now);
    }

    final updated = Medication(
      id: old.id,
      userId: old.userId,
      drugName: old.drugName,
      dosage: old.dosage,
      frequency: old.frequency,
      whenToTake: old.whenToTake,
      prescribedBy: old.prescribedBy,
      startDate: old.startDate,
      endDate: old.endDate,
      status: old.status,
      stopReason: old.stopReason,
      notes: old.notes,
      takenDates: updatedTaken,
    );

    await _hiveService.putItem(HiveService.boxMedications, updated.id, updated.toMap());
    _medications[idx] = updated;
    notifyListeners();
  }

  Future<void> stopMedication(String medicationId, String reason) async {
    final idx = _medications.indexWhere((m) => m.id == medicationId);
    if (idx == -1) return;

    final old = _medications[idx];

    // Push to backend
    try {
      await _api.put('/prescription/medications/$medicationId', {
        'status': 'stopped',
        'stop_reason': reason.trim(),
      });
    } catch (e) {
      if (kDebugMode) print('Failed to push medication stop to backend: $e');
    }

    final updated = Medication(
      id: old.id,
      userId: old.userId,
      drugName: old.drugName,
      dosage: old.dosage,
      frequency: old.frequency,
      whenToTake: old.whenToTake,
      prescribedBy: old.prescribedBy,
      startDate: old.startDate,
      endDate: DateTime.now(),
      status: 'stopped',
      stopReason: reason.trim(),
      notes: old.notes,
      takenDates: old.takenDates,
    );

    await _hiveService.putItem(HiveService.boxMedications, updated.id, updated.toMap());
    _medications[idx] = updated;

    // Create a health history event
    _createHistoryEvent(
      type: 'medication',
      title: 'Medication Stopped',
      description: 'Stopped ${old.drugName} — Reason: ${reason.trim()}.',
    );

    notifyListeners();
  }

  Future<void> deleteMedication(String medicationId) async {
    // Push to backend
    try {
      await _api.delete('/prescription/medications/$medicationId');
    } catch (e) {
      if (kDebugMode) print('Failed to push medication delete to backend: $e');
    }

    await _hiveService.deleteItem(HiveService.boxMedications, medicationId);
    _medications.removeWhere((m) => m.id == medicationId);
    notifyListeners();
  }

  List<InteractionCheckResult> evaluateNewMedication(String drugName, List<String> drugAllergies) {
    return _interactionService.evaluateNewMedication(
      newDrugName: drugName,
      activeMeds: activeMedications,
      drugAllergies: drugAllergies,
    );
  }

  /// Fire-and-forget history event creation via backend API.
  void _createHistoryEvent({
    required String type,
    required String title,
    required String description,
  }) {
    _api.post('/history/', {
      'type': type,
      'title': title,
      'description': description,
    }).catchError((_) {});
  }
}
