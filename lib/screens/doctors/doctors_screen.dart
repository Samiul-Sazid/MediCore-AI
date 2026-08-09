import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  void _openDoctorDetail(Doctor doctor) {
    context.go('/doctors/detail', extra: doctor);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doctor & Specialist Matching', style: AppTypography.displaySmall),
                      Text('Input your symptoms to find matched clinical specialists', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/doctors/appointments'),
                  icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                  label: Text(
                    'My Appointments',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
              suggestions: const ['Chest pain', 'Headache', 'Joint pain', 'Rash', 'Fatigue', 'Dizziness', 'Palpitations', 'Breathing difficulty', 'Stomach pain', 'Anxiety'],
              onAdd: (s) => docProvider.addSymptom(s),
              onRemove: (s) => docProvider.removeSymptom(s),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: docProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : docProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              Text(docProvider.errorMessage!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              GradientButton(
                                text: 'Retry',
                                icon: Icons.refresh,
                                onPressed: () => docProvider.loadDoctors(),
                              ),
                            ],
                          ),
                        )
                      : doctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_search, color: AppColors.textMuted, size: 48),
                                  const SizedBox(height: 12),
                                  Text('No matching doctors found.', style: AppTypography.bodyMedium),
                                  Text('Try different symptoms or search terms.', style: AppTypography.bodySmall),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: doctors.length,
                              itemBuilder: (context, index) {
                                final doc = doctors[index];
                                return _buildDoctorCard(doc);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doc) {
    return GestureDetector(
      onTap: () => _openDoctorDetail(doc),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: doc.photoUrl.isNotEmpty ? NetworkImage(doc.photoUrl) : null,
              child: doc.photoUrl.isEmpty
                  ? Text(
                      doc.name.split(' ').last[0],
                      style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(doc.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
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
                      Text('${doc.rating} (${doc.reviewCount})', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text('${doc.experienceYears} yrs exp', style: AppTypography.bodySmall),
                      if (doc.consultationFee > 0) ...[
                        const SizedBox(width: 12),
                        Text('\$${doc.consultationFee.toStringAsFixed(0)}', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
