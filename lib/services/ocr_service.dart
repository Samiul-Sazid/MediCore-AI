import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import 'interaction_service.dart';
import 'api_client.dart';

/// OCR service that sends prescription images to the backend for
/// Claude Vision-powered parsing — accurate extraction of drug info.
class OCRService {
  final InteractionService _interactionService = InteractionService();
  final ApiClient _api = ApiClient();
  final Uuid _uuid = const Uuid();

  Future<ScanResult> processPrescriptionImage({
    required String userId,
    required String imageBase64OrPath,
    required UserProfile profile,
    required List<Medication> activeMeds,
  }) async {
    String drugName = 'Unknown Drug';
    String dosage = 'N/A';
    String frequency = 'N/A';
    String instructions = 'No instructions found';
    String prescribedBy = 'N/A';
    int durationDays = 30;
    double confidenceScore = 0.0;
    List<String> allergyWarnings = [];
    List<String> interactionWarnings = [];

    try {
      // Send image to backend OCR endpoint (Claude Vision)
      final response = await _api.post('/ocr/parse', {
        'image': imageBase64OrPath,
      });

      if (response != null) {
        drugName = response['drugName'] ?? 'Unknown Drug';
        dosage = response['dosage'] ?? 'N/A';
        frequency = response['frequency'] ?? 'N/A';
        instructions = response['instructions'] ?? 'No instructions found';
        prescribedBy = response['prescribedBy'] ?? 'N/A';
        durationDays = (response['durationDays'] ?? 30) is int
            ? response['durationDays']
            : int.tryParse(response['durationDays'].toString()) ?? 30;
        confidenceScore = (response['confidenceScore'] ?? 0.0) is double
            ? response['confidenceScore']
            : double.tryParse(response['confidenceScore'].toString()) ?? 0.0;

        // Backend may return warnings directly
        if (response['allergyWarning'] != null) {
          allergyWarnings.add(response['allergyWarning']);
        }
        if (response['interactionWarnings'] != null && response['interactionWarnings'] is List) {
          interactionWarnings = List<String>.from(response['interactionWarnings']);
        }
      }
    } catch (e) {
      print('OCR API Error: $e');
      drugName = 'Error reading prescription';
      instructions = 'Could not process image. Please try again with a clearer photo.';
    }

    // Local safety checks (in addition to backend checks)
    final safetyAlerts = _interactionService.evaluateNewMedication(
      newDrugName: drugName,
      activeMeds: activeMeds,
      drugAllergies: profile.drugAllergies,
    );

    final localAllergyWarnings = safetyAlerts
        .where((a) => a.severity == 'allergy')
        .map((a) => a.description)
        .toList();

    final localInteractionWarnings = safetyAlerts
        .where((a) => a.severity != 'allergy')
        .map((a) => '[${a.severity.toUpperCase()}] ${a.title}: ${a.description}')
        .toList();

    // Merge backend and local warnings (deduplicate)
    allergyWarnings = {...allergyWarnings, ...localAllergyWarnings}.toList();
    interactionWarnings = {...interactionWarnings, ...localInteractionWarnings}.toList();

    return ScanResult(
      id: _uuid.v4(),
      userId: userId,
      imageData: imageBase64OrPath.length > 100 ? 'base64_image_data' : imageBase64OrPath,
      extractedData: {
        'drugName': drugName,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'prescribedBy': prescribedBy,
        'durationDays': durationDays,
        'confidenceScore': confidenceScore,
      },
      allergyWarnings: allergyWarnings,
      interactionWarnings: interactionWarnings,
      scannedAt: DateTime.now(),
    );
  }
}
