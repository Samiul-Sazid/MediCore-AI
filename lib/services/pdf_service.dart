import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/user_account.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../models/health_event.dart';

class PdfService {
  Future<Uint8List> generateHealthReport({
    required UserAccount account,
    required UserProfile profile,
    required List<Medication> activeMeds,
    required List<HealthEvent> recentEvents,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with App Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MediCore AI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('Comprehensive Personal Medical Health Summary', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Report Date: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Patient ID: ${account.id.substring(0, 8)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.teal, thickness: 2),
            pw.SizedBox(height: 16),

            // Patient Information Section
            pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Name: ${account.fullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('Email: ${account.email}')),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Gender: ${profile.gender}')),
                      pw.Expanded(child: pw.Text('Blood Type: ${profile.bloodType}')),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Weight: ${profile.weightKg} kg')),
                      pw.Expanded(child: pw.Text('Height: ${profile.heightCm} cm (BMI: ${profile.bmi.toStringAsFixed(1)})')),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Emergency Contact: ${profile.emergencyContactName} (${profile.emergencyContactRelation})')),
                      pw.Expanded(child: pw.Text('Phone: ${profile.emergencyContactPhone}')),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Medical Profile & Allergies
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DOCUMENTED CONDITIONS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                      pw.SizedBox(height: 4),
                      if (profile.conditions.isEmpty)
                        pw.Text('No chronic conditions listed.', style: const pw.TextStyle(fontSize: 10))
                      else
                        pw.Bullet(text: profile.conditions.join(', '), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DRUG & FOOD ALLERGIES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                      pw.SizedBox(height: 4),
                      if (profile.drugAllergies.isEmpty && profile.foodAllergies.isEmpty)
                        pw.Text('No allergies documented.', style: const pw.TextStyle(fontSize: 10))
                      else ...[
                        if (profile.drugAllergies.isNotEmpty) pw.Text('Drug: ${profile.drugAllergies.join(", ")}', style: const pw.TextStyle(fontSize: 10)),
                        if (profile.foodAllergies.isNotEmpty) pw.Text('Food: ${profile.foodAllergies.join(", ")}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Active Medications Table
            pw.Text('ACTIVE MEDICATIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 8),
            if (activeMeds.isEmpty)
              pw.Text('No active medications on record.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellHeight: 24,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                },
                data: <List<String>>[
                  <String>['Medication Name', 'Dosage', 'Frequency', 'Prescribed By'],
                  ...activeMeds.map((m) => [m.drugName, m.dosage, m.frequency, m.prescribedBy.isEmpty ? 'N/A' : m.prescribedBy]),
                ],
              ),
            pw.SizedBox(height: 16),

            // Timeline History
            pw.Text('RECENT HEALTH TIMELINE EVENTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 8),
            if (recentEvents.isEmpty)
              pw.Text('No recent timeline events.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.Column(
                children: recentEvents.take(6).map((e) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                  child: pw.Row(
                    children: [
                      pw.Text(dateFormat.format(e.date), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(e.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text(e.description, style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              'CONFIDENTIAL MEDICAL RECORD — Generated automatically by MediCore AI. This report is intended for informational review by healthcare professionals.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> shareOrPrintReport({
    required UserAccount account,
    required UserProfile profile,
    required List<Medication> activeMeds,
    required List<HealthEvent> recentEvents,
  }) async {
    final pdfBytes = await generateHealthReport(
      account: account,
      profile: profile,
      activeMeds: activeMeds,
      recentEvents: recentEvents,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'MediCore_Health_Report_${account.lastName}.pdf',
    );
  }
}
