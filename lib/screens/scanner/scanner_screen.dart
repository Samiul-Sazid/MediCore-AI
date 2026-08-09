import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  void _pickAndScanPrescription(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final medProvider = Provider.of<MedicationProvider>(context, listen: false);
      final scannerProvider = Provider.of<ScannerProvider>(context, listen: false);

      final user = authProvider.currentUser;
      final profile = profileProvider.profile;
      
      if (user != null && profile != null) {
        final file = result.files.first;
        String base64Image = '';
        if (file.bytes != null) {
          base64Image = base64Encode(file.bytes!);
        }

        await scannerProvider.scanPrescription(
          userId: user.id,
          imageBase64OrPath: base64Image,
          profile: profile,
          activeMeds: medProvider.activeMedications,
        );
      }
    }
  }

  void _saveScannedToMedications(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final medProvider = Provider.of<MedicationProvider>(context, listen: false);
    final scannerProvider = Provider.of<ScannerProvider>(context, listen: false);
    final scan = scannerProvider.lastScanResult;

    if (scan != null && authProvider.currentUser != null) {
      final data = scan.extractedData;
      await medProvider.addMedication(
        userId: authProvider.currentUser!.id,
        drugName: data['drugName'] ?? 'Unknown Drug',
        dosage: data['dosage'] ?? '',
        frequency: data['frequency'] ?? 'Daily',
        whenToTake: 'With meals',
        prescribedBy: data['prescribedBy'] ?? '',
        notes: data['instructions'] ?? '',
      );

      scannerProvider.clearLastResult();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription added directly to your Active Medications!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerProvider = Provider.of<ScannerProvider>(context);
    final lastResult = scannerProvider.lastScanResult;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Prescription OCR Scanner', style: AppTypography.displaySmall),
            Text('Upload or snap a prescription label for instant extraction & allergy cross-checking', style: AppTypography.bodySmall),
            const SizedBox(height: 24),

            // Scan Action Card
            GlassCard(
              padding: const EdgeInsets.all(32),
              gradient: AppColors.primaryGradient,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner, color: Colors.black, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI Optical Character Recognition (OCR)',
                      style: AppTypography.titleLarge.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Extracts drug name, dosage, doctor details & checks interaction safety instantly.',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: scannerProvider.isScanning ? 'Analyzing Label Image...' : 'Upload Prescription Label Image',
                      icon: Icons.camera_alt,
                      gradient: const [Colors.black, Color(0xFF1F2937)],
                      isLoading: scannerProvider.isScanning,
                      onPressed: scannerProvider.isScanning ? null : () => _pickAndScanPrescription(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Scan Result View
            if (lastResult != null) ...[
              Text('OCR Extraction Results', style: AppTypography.titleLarge),
              const SizedBox(height: 14),

              // Allergy & Interaction Warnings
              if (lastResult.allergyWarnings.isNotEmpty || lastResult.interactionWarnings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'SAFETY ALERTS DETECTED',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...lastResult.allergyWarnings.map((w) => Text('• $w', style: AppTypography.bodySmall.copyWith(color: AppColors.danger))),
                      ...lastResult.interactionWarnings.map((w) => Text('• $w', style: AppTypography.bodySmall.copyWith(color: AppColors.warning))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lastResult.extractedData['drugName'] ?? 'Unknown',
                          style: AppTypography.displayMedium.copyWith(fontSize: 24, color: AppColors.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OCR Confidence: ${lastResult.extractedData['confidenceScore']}%',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDataRow('Dosage:', lastResult.extractedData['dosage']),
                    _buildDataRow('Frequency:', lastResult.extractedData['frequency']),
                    _buildDataRow('Prescribing Doctor:', lastResult.extractedData['prescribedBy']),
                    _buildDataRow('Instructions:', lastResult.extractedData['instructions']),
                    const SizedBox(height: 20),

                    GradientButton(
                      text: 'Add directly to Active Medications',
                      icon: Icons.check,
                      width: double.infinity,
                      onPressed: () => _saveScannedToMedications(context),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
