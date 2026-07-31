import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import 'interaction_service.dart';

class OCRService {
  final InteractionService _interactionService = InteractionService();
  final Uuid _uuid = const Uuid();

  // Simulated prescription repository
  static final List<Map<String, dynamic>> _samplePrescriptions = [
    {
      'drugName': 'Lisinopril',
      'dosage': '10mg',
      'frequency': 'Once daily (morning)',
      'instructions': 'Take 1 tablet by mouth every morning with water.',
      'prescribedBy': 'Dr. Elena Rostova, MD',
      'durationDays': 30,
    },
    {
      'drugName': 'Amoxicillin',
      'dosage': '500mg',
      'frequency': 'Three times daily',
      'instructions': 'Take 1 capsule every 8 hours with meals for 10 days.',
      'prescribedBy': 'Dr. Marcus Vance, DO',
      'durationDays': 10,
    },
    {
      'drugName': 'Atorvastatin',
      'dosage': '20mg',
      'frequency': 'Once daily (bedtime)',
      'instructions': 'Take 1 tablet before sleeping to manage cholesterol.',
      'prescribedBy': 'Dr. Sarah Lin, FACC',
      'durationDays': 90,
    },
    {
      'drugName': 'Ibuprofen',
      'dosage': '400mg',
      'frequency': 'Every 6 hours as needed',
      'instructions': 'Take 1 tablet with food for pain or inflammation.',
      'prescribedBy': 'Dr. Jonathan Reed, MD',
      'durationDays': 7,
    },
    {
      'drugName': 'Metformin',
      'dosage': '800mg',
      'frequency': 'Twice daily',
      'instructions': 'Take 1 tablet morning and evening with food.',
      'prescribedBy': 'Dr. Aris Thorne, MD',
      'durationDays': 60,
    },
  ];

  Future<ScanResult> processPrescriptionImage({
    required String userId,
    required String imageBase64OrPath,
    required UserProfile profile,
    required List<Medication> activeMeds,
  }) async {
    // Simulate OCR scanning latency
    await Future.delayed(const Duration(milliseconds: 1800));

    final random = Random();
    final sample = _samplePrescriptions[random.nextInt(_samplePrescriptions.length)];

    final drugName = sample['drugName'] as String;

    // Safety checks against patient profile
    final safetyAlerts = _interactionService.evaluateNewMedication(
      newDrugName: drugName,
      activeMeds: activeMeds,
      drugAllergies: profile.drugAllergies,
    );

    final allergyWarnings = safetyAlerts
        .where((a) => a.severity == 'allergy')
        .map((a) => a.description)
        .toList();

    final interactionWarnings = safetyAlerts
        .where((a) => a.severity != 'allergy')
        .map((a) => '[${a.severity.toUpperCase()}] ${a.title}: ${a.description}')
        .toList();

    return ScanResult(
      id: _uuid.v4(),
      userId: userId,
      imageData: imageBase64OrPath,
      extractedData: {
        'drugName': sample['drugName'],
        'dosage': sample['dosage'],
        'frequency': sample['frequency'],
        'instructions': sample['instructions'],
        'prescribedBy': sample['prescribedBy'],
        'durationDays': sample['durationDays'],
        'confidenceScore': (88 + random.nextInt(11)).toDouble(),
      },
      allergyWarnings: allergyWarnings,
      interactionWarnings: interactionWarnings,
      scannedAt: DateTime.now(),
    );
  }
}
