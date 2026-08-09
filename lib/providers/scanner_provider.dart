import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../services/ocr_service.dart';
import '../services/hive_service.dart';
import '../services/api_client.dart';

class ScannerProvider with ChangeNotifier {
  final OCRService _ocrService = OCRService();
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();

  bool _isScanning = false;
  ScanResult? _lastScanResult;
  List<ScanResult> _scanHistory = [];

  bool get isScanning => _isScanning;
  ScanResult? get lastScanResult => _lastScanResult;
  List<ScanResult> get scanHistory => _scanHistory;

  Future<void> loadScanHistory(String userId) async {
    try {
      final data = await _api.get('/prescription/');
      if (data != null && data is List) {
        // Sync backend prescriptions into local scan history
        for (var p in data) {
          final scanId = 'rx-${p['id']}';
          final result = ScanResult(
            id: scanId,
            userId: userId,
            imageData: '',
            extractedData: {
              'drugName': p['drug_name'] ?? '',
              'dosage': p['dosage'] ?? '',
              'frequency': p['frequency'] ?? '',
              'instructions': p['raw_text'] ?? '',
              'prescribedBy': p['prescribed_by'] ?? '',
              'durationDays': p['duration_days'] ?? 30,
              'confidenceScore': p['confidence_score'] ?? 0.0,
            },
            allergyWarnings: [],
            interactionWarnings: [],
            scannedAt: p['scanned_at'] != null
                ? DateTime.tryParse(p['scanned_at']) ?? DateTime.now()
                : DateTime.now(),
          );
          await _hiveService.putItem(HiveService.boxScanHistory, scanId, result.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load scan history from API: $e');
    }

    final raw = _hiveService.getAllItems(HiveService.boxScanHistory);
    _scanHistory = raw
        .where((map) => map['userId'] == userId)
        .map((map) => ScanResult.fromMap(map))
        .toList();
    _scanHistory.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    notifyListeners();
  }

  Future<ScanResult?> scanPrescription({
    required String userId,
    required String imageBase64OrPath,
    required UserProfile profile,
    required List<Medication> activeMeds,
  }) async {
    _isScanning = true;
    _lastScanResult = null;
    notifyListeners();

    try {
      final result = await _ocrService.processPrescriptionImage(
        userId: userId,
        imageBase64OrPath: imageBase64OrPath,
        profile: profile,
        activeMeds: activeMeds,
      );

      _lastScanResult = result;
      await _hiveService.putItem(HiveService.boxScanHistory, result.id, result.toMap());
      _scanHistory.insert(0, result);
      
      // Push to backend
      try {
        await _api.post('/prescription/upload', {
          'prescribedBy': result.extractedData['prescribedBy'],
          'rawText': result.extractedData['instructions'],
          'drugName': result.extractedData['drugName'],
          'dosage': result.extractedData['dosage'],
          'frequency': result.extractedData['frequency'],
          'durationDays': result.extractedData['durationDays'],
          'confidence_score': result.extractedData['confidenceScore'],
        });
      } catch (e) {
        if (kDebugMode) print('Failed to push prescription to API: $e');
      }

      // Create history event
      final drugName = result.extractedData['drugName'] ?? 'Unknown';
      _api.post('/history/', {
        'type': 'scan',
        'title': 'Prescription Scanned',
        'description': 'Scanned prescription for $drugName.',
      }).catchError((_) {});

      return result;
    } catch (e) {
      if (kDebugMode) print('OCR Scan failed: $e');
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearLastResult() {
    _lastScanResult = null;
    notifyListeners();
  }
}
