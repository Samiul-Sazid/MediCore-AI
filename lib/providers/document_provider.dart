import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/document_record.dart';
import '../services/hive_service.dart';
import '../services/api_client.dart';

class DocumentProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final ApiClient _api = ApiClient();
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
    // Try loading from backend API
    try {
      final data = await _api.get('/documents/');
      if (data != null && data is List) {
        for (var docData in data) {
          final doc = DocumentRecord(
            id: docData['id'].toString(),
            userId: userId,
            fileName: docData['file_name'] ?? '',
            fileType: docData['file_type'] ?? '',
            fileData: '', // Not included in list response for performance
            category: docData['category'] ?? 'Other',
            uploadedAt: docData['uploaded_at'] != null
                ? DateTime.tryParse(docData['uploaded_at']) ?? DateTime.now()
                : DateTime.now(),
            fileSize: docData['file_size'] ?? 0,
          );
          await _hiveService.putItem(HiveService.boxDocuments, doc.id, doc.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load documents from backend: $e');
    }

    // Load from Hive (includes backend-synced + local-only documents)
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
    String docId = _uuid.v4();

    // Push to backend
    try {
      final response = await _api.post('/documents/upload', {
        'file_name': fileName,
        'file_type': fileType,
        'category': category,
        'file_data': base64Data,
        'file_size': bytes.length,
      });
      if (response != null && response['id'] != null) {
        docId = response['id'].toString();
      }
    } catch (e) {
      if (kDebugMode) print('Failed to push document to backend: $e');
    }

    final doc = DocumentRecord(
      id: docId,
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

    // Create history event
    _api.post('/history/', {
      'type': 'document',
      'title': 'Document Uploaded',
      'description': 'Uploaded "$fileName" to $category.',
    }).catchError((_) {});

    notifyListeners();
    return doc;
  }

  Future<void> deleteDocument(String documentId) async {
    // Push to backend
    try {
      await _api.delete('/documents/$documentId');
    } catch (e) {
      if (kDebugMode) print('Failed to delete document from backend: $e');
    }

    await _hiveService.deleteItem(HiveService.boxDocuments, documentId);
    _documents.removeWhere((d) => d.id == documentId);
    notifyListeners();
  }
}
