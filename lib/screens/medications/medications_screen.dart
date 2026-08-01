import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/medication_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddMedicationModal() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final doctorController = TextEditingController();
    final notesController = TextEditingController();
    String whenToTake = 'With meals';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final medProvider = Provider.of<MedicationProvider>(context, listen: false);
            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
            final userId = authProvider.currentUser?.id ?? '';
            final allergies = profileProvider.profile?.drugAllergies ?? [];

            // Check interactions in real-time
            final safetyAlerts = medProvider.evaluateNewMedication(nameController.text, allergies);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Prescription', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                    const SizedBox(height: 16),

                    if (safetyAlerts.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: safetyAlerts.map((alert) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${alert.title}: ${alert.description}',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextField(
                      controller: nameController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(labelText: 'Drug / Medication Name'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dosageController,
                            decoration: const InputDecoration(labelText: 'Dosage (e.g. 10mg)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: frequencyController,
                            decoration: const InputDecoration(labelText: 'Frequency (e.g. Once daily)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: whenToTake,
                      decoration: const InputDecoration(labelText: 'When to Take'),
                      dropdownColor: AppColors.surface,
                      items: ['With meals', 'Before meals', 'After meals', 'Bedtime', 'As needed']
                          .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                          .toList(),
                      onChanged: (val) => setModalState(() => whenToTake = val ?? 'With meals'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(labelText: 'Prescribing Physician'),
                    ),
                    const SizedBox(height: 20),

                    GradientButton(
                      text: 'Add to Active Prescriptions',
                      width: double.infinity,
                      onPressed: () async {
                        if (nameController.text.trim().isNotEmpty) {
                          await medProvider.addMedication(
                            userId: userId,
                            drugName: nameController.text,
                            dosage: dosageController.text,
                            frequency: frequencyController.text,
                            whenToTake: whenToTake,
                            prescribedBy: doctorController.text,
                            notes: notesController.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStopMedicationModal(String medicationId) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Discontinue Medication', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Discontinuing (e.g. Side effects, Course completed)',
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Confirm Discontinuation',
                gradient: const [AppColors.warning, Colors.deepOrange],
                width: double.infinity,
                onPressed: () async {
                  await Provider.of<MedicationProvider>(context, listen: false).stopMedication(
                    medicationId,
                    reasonController.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = Provider.of<MedicationProvider>(context);

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
                    Text('Medication Management', style: AppTypography.displaySmall),
                    Text('Track active prescriptions & automated drug safety checks', style: AppTypography.bodySmall),
                  ],
                ),
                GradientButton(
                  text: 'Add Prescription',
                  icon: Icons.add,
                  onPressed: _showAddMedicationModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(text: 'Active Prescriptions (${medProvider.activeMedications.length})'),
                Tab(text: 'Past / Stopped (${medProvider.stoppedMedications.length})'),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active Tab
                  medProvider.activeMedications.isEmpty
                      ? EmptyState(
                          icon: Icons.medication_outlined,
                          title: 'No Active Medications',
                          description: 'Add a new prescription to track daily dosages and safety alerts.',
                          buttonText: 'Add First Prescription',
                          onButtonTap: _showAddMedicationModal,
                        )
                      : ListView.builder(
                          itemCount: medProvider.activeMedications.length,
                          itemBuilder: (context, index) {
                            final med = medProvider.activeMedications[index];
                            return MedicationCard(
                              medication: med,
                              onToggleTaken: () => medProvider.toggleTakenToday(med.id),
                              onStop: () => _showStopMedicationModal(med.id),
                              onDelete: () => medProvider.deleteMedication(med.id),
                            );
                          },
                        ),

                  // Stopped Tab
                  medProvider.stoppedMedications.isEmpty
                      ? const EmptyState(
                          icon: Icons.history,
                          title: 'No Stopped Medications',
                          description: 'Medications you discontinue will appear here.',
                        )
                      : ListView.builder(
                          itemCount: medProvider.stoppedMedications.length,
                          itemBuilder: (context, index) {
                            final med = medProvider.stoppedMedications[index];
                            return MedicationCard(
                              medication: med,
                              onDelete: () => medProvider.deleteMedication(med.id),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
