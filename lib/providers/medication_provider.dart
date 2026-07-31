import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../services/hive_service.dart';
import '../services/interaction_service.dart';

class MedicationProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final InteractionService _interactionService = InteractionService();
  final Uuid _uuid = const Uuid();

  List<Medication> _medications = [];

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => _medications.where((m) => m.isActive).toList();
  List<Medication> get stoppedMedications => _medications.where((m) => !m.isActive).toList();

  Future<void> loadMedications(String userId) async {
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
    final med = Medication(
      id: _uuid.v4(),
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
    notifyListeners();
  }

  Future<void> deleteMedication(String medicationId) async {
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
}
