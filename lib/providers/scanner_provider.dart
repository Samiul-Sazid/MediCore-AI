import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../services/ocr_service.dart';
import '../services/hive_service.dart';

class ScannerProvider with ChangeNotifier {
  final OCRService _ocrService = OCRService();
  final HiveService _hiveService = HiveService();

  bool _isScanning = false;
  ScanResult? _lastScanResult;
  List<ScanResult> _scanHistory = [];

  bool get isScanning => _isScanning;
  ScanResult? get lastScanResult => _lastScanResult;
  List<ScanResult> get scanHistory => _scanHistory;

  Future<void> loadScanHistory(String userId) async {
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
