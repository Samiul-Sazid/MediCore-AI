import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../providers/doctor_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/search_chip_field.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _searchController = TextEditingController();

  void _bookDoctorModal(Doctor doctor) {
    String selectedDay = doctor.availableDays.first;

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
                  Text('Book Consultation', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text('${doctor.name} • ${doctor.specialty}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                  Text(doctor.hospital, style: AppTypography.bodySmall),
                  const SizedBox(height: 20),

                  Text('Select Preferred Appointment Day:', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: doctor.availableDays.map((day) {
                      final isSelected = selectedDay == day;
                      return ChoiceChip(
                        label: Text(day),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardBg,
                        labelStyle: TextStyle(color: isSelected ? Colors.black : AppColors.textPrimary),
                        onSelected: (_) => setModalState(() => selectedDay = day),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  GradientButton(
                    text: 'Confirm Appointment Request',
                    width: double.infinity,
                    onPressed: () {
                      Provider.of<DoctorProvider>(context, listen: false).bookAppointment(doctor);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Appointment requested with ${doctor.name} for $selectedDay!')),
                      );
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

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final doctors = docProvider.doctors;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor & Specialist Matching', style: AppTypography.displaySmall),
            Text('Input your symptoms to find matched clinical specialists near you', style: AppTypography.bodySmall),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (q) => docProvider.search(query: q),
              decoration: const InputDecoration(
                hintText: 'Search doctor by name, specialty, or hospital...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Symptom Chip Input
            SearchChipField(
              selectedChips: docProvider.selectedSymptoms,
              hintText: 'Type symptom to filter matching specialists (e.g. Chest pain)...',
              suggestions: const ['Chest pain', 'Headache', 'Joint pain', 'Rash', 'Fatigue', 'Dizziness', 'Palpitations'],
              onAdd: (s) => docProvider.addSymptom(s),
              onRemove: (s) => docProvider.removeSymptom(s),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: doctors.isEmpty
                  ? Center(
                      child: Text('No matching doctors found for your search criteria.', style: AppTypography.bodyMedium),
                    )
                  : ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doc = doctors[index];
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  doc.name.split(' ').last[0],
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(doc.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(doc.specialty, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(doc.hospital, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: AppColors.warning, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${doc.rating} (${doc.reviewCount} reviews)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 16),
                                        Text('${doc.distanceKm} km away', style: AppTypography.bodySmall),
                                        const SizedBox(width: 12),
                                        Text('${doc.experienceYears} yrs exp', style: AppTypography.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GradientButton(
                                text: 'Book',
                                height: 40,
                                onPressed: () => _bookDoctorModal(doc),
                              ),
                            ],
                          ),
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
