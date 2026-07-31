import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/document_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final List<String> _categories = ['All', 'Lab Results', 'Prescriptions', 'Imaging', 'Insurance', 'Other'];

  void _uploadDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && mounted) {
      final file = result.files.first;
      final bytes = file.bytes ?? Uint8List(0);
      final fileName = file.name;
      final extension = file.extension ?? 'other';

      String category = 'Lab Results';

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categorize Document Upload', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                    const SizedBox(height: 12),
                    Text('File: $fileName (${(bytes.length / 1024).toStringAsFixed(1)} KB)', style: AppTypography.bodySmall),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Document Category'),
                      dropdownColor: AppColors.surface,
                      items: ['Lab Results', 'Prescriptions', 'Imaging', 'Insurance', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setModalState(() => category = val ?? 'Other'),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Save Document to Vault',
                      width: double.infinity,
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final docProvider = Provider.of<DocumentProvider>(context, listen: false);
                        final userId = authProvider.currentUser?.id ?? '';

                        await docProvider.addDocument(
                          userId: userId,
                          fileName: fileName,
                          fileType: extension,
                          bytes: bytes,
                          category: category,
                        );
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  void _previewDocument(DocumentRecord doc) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doc.fileName,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: doc.fileType == 'pdf'
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.danger),
                              const SizedBox(height: 12),
                              Text('PDF Health Document Encrypted Payload', style: AppTypography.titleSmall),
                              Text('${doc.formattedSize} • ${doc.category}', style: AppTypography.bodySmall),
                            ],
                          ),
                        )
                      : doc.fileData.isNotEmpty
                          ? Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(doc.fileData),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                                ),
                              ),
                            )
                          : const Center(child: Text('Document preview ready')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final documents = docProvider.filteredDocuments;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Document Vault', style: AppTypography.displaySmall),
                    Text('Total Vault Storage: ${docProvider.formattedTotalStorage}', style: AppTypography.bodySmall),
                  ],
                ),
                GradientButton(
                  text: 'Upload Document',
                  icon: Icons.upload_file,
                  onPressed: _uploadDocument,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = docProvider.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => docProvider.selectCategory(category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: documents.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open,
                      title: 'No Documents Found',
                      description: 'Upload your lab results, prescriptions, or imaging reports to keep them encrypted in your health vault.',
                      buttonText: 'Upload Document',
                      onButtonTap: _uploadDocument,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () => _previewDocument(doc),
                              onDelete: () => docProvider.deleteDocument(doc.id),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
