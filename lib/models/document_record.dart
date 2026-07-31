class DocumentRecord {
  final String id;
  final String userId;
  final String fileName;
  final String fileType; // 'pdf' | 'jpg' | 'png' | 'other'
  final String fileData; // base64 payload or simulated path
  final String category; // 'Lab Results' | 'Prescriptions' | 'Imaging' | 'Insurance' | 'Other'
  final DateTime uploadedAt;
  final int fileSize; // bytes

  DocumentRecord({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.fileData,
    required this.category,
    required this.uploadedAt,
    required this.fileSize,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileType': fileType,
      'fileData': fileData,
      'category': category,
      'uploadedAt': uploadedAt.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  factory DocumentRecord.fromMap(Map<dynamic, dynamic> map) {
    return DocumentRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? 'other',
      fileData: map['fileData'] ?? '',
      category: map['category'] ?? 'Other',
      uploadedAt: map['uploadedAt'] != null ? DateTime.parse(map['uploadedAt']) : DateTime.now(),
      fileSize: map['fileSize'] ?? 0,
    );
  }
}
