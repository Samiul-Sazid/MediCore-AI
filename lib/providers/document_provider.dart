import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/document_record.dart';
import '../services/hive_service.dart';

class DocumentProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final Uuid _uuid = const Uuid();

  List<DocumentRecord> _documents = [];
  String _selectedCategory = 'All';

  List<DocumentRecord> get documents => _documents;
  String get selectedCategory => _selectedCategory;

  List<DocumentRecord> get filteredDocuments {
    if (_selectedCategory == 'All') return _documents;
    return _documents.where((d) => d.category == _selectedCategory).toList();
  }

  int get totalStorageBytes {
    return _documents.fold(0, (sum, doc) => sum + doc.fileSize);
  }

  String get formattedTotalStorage {
    final bytes = totalStorageBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> loadDocuments(String userId) async {
    final raw = _hiveService.getAllItems(HiveService.boxDocuments);
    _documents = raw
        .where((map) => map['userId'] == userId)
        .map((map) => DocumentRecord.fromMap(map))
        .toList();
    _documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<DocumentRecord> addDocument({
    required String userId,
    required String fileName,
    required String fileType,
    required Uint8List bytes,
    required String category,
  }) async {
    final base64Data = base64Encode(bytes);
    final doc = DocumentRecord(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      fileType: fileType,
      fileData: base64Data,
      category: category,
      uploadedAt: DateTime.now(),
      fileSize: bytes.length,
    );

    await _hiveService.putItem(HiveService.boxDocuments, doc.id, doc.toMap());
    _documents.insert(0, doc);
    notifyListeners();
    return doc;
  }

  Future<void> deleteDocument(String documentId) async {
    await _hiveService.deleteItem(HiveService.boxDocuments, documentId);
    _documents.removeWhere((d) => d.id == documentId);
    notifyListeners();
  }
}
