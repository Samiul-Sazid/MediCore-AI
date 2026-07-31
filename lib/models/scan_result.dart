class ScanResult {
  final String id;
  final String userId;
  final String imageData; // base64 or path
  final Map<String, dynamic> extractedData; // drugName, dosage, frequency, instructions, doctor, duration
  final List<String> allergyWarnings;
  final List<String> interactionWarnings;
  final DateTime scannedAt;

  ScanResult({
    required this.id,
    required this.userId,
    required this.imageData,
    required this.extractedData,
    this.allergyWarnings = const [],
    this.interactionWarnings = const [],
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageData': imageData,
      'extractedData': extractedData,
      'allergyWarnings': allergyWarnings,
      'interactionWarnings': interactionWarnings,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory ScanResult.fromMap(Map<dynamic, dynamic> map) {
    return ScanResult(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      imageData: map['imageData'] ?? '',
      extractedData: Map<String, dynamic>.from(map['extractedData'] ?? {}),
      allergyWarnings: List<String>.from(map['allergyWarnings'] ?? []),
      interactionWarnings: List<String>.from(map['interactionWarnings'] ?? []),
      scannedAt: map['scannedAt'] != null ? DateTime.parse(map['scannedAt']) : DateTime.now(),
    );
  }
}
