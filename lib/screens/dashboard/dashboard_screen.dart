import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/history_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/medication_tracker_tile.dart';
import '../../widgets/timeline_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/empty_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ProfileProvider>(context, listen: false).loadProfile(user.id);
        Provider.of<MedicationProvider>(context, listen: false).loadMedications(user.id);
        Provider.of<DocumentProvider>(context, listen: false).loadDocuments(user.id);
        Provider.of<HistoryProvider>(context, listen: false).loadEvents(user.id);
      }
    });
  }

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final profile = Provider.of<ProfileProvider>(context).profile;
    final medProvider = Provider.of<MedicationProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);

    if (user == null) return const Center(child: CircularProgressIndicator());

    final activeMeds = medProvider.activeMedications;
    final allergiesCount = (profile?.drugAllergies.length ?? 0) + (profile?.foodAllergies.length ?? 0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            GlassCard(
              padding: const EdgeInsets.all(24),
              gradient: AppColors.primaryGradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_timeOfDayGreeting, ${user.firstName}!',
                          style: AppTypography.displaySmall.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your MediCore AI health engine is active & monitoring vital telemetries.',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.black, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Overview Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.4 : 1.2,
                  children: [
                    StatCard(
                      title: 'Active Meds',
                      value: '${activeMeds.length}',
                      subtitle: 'Daily Dosing',
                      icon: Icons.medication_liquid_outlined,
                      iconColor: AppColors.primary,
                      onTap: () => context.go('/medications'),
                    ),
                    StatCard(
                      title: 'Health Records',
                      value: '${docProvider.documents.length}',
                      subtitle: docProvider.formattedTotalStorage,
                      icon: Icons.folder_open_outlined,
                      iconColor: AppColors.secondary,
                      onTap: () => context.go('/documents'),
                    ),
                    StatCard(
                      title: 'Known Allergies',
                      value: '$allergiesCount',
                      subtitle: 'Safety Guard',
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.warning,
                      onTap: () => context.go('/profile'),
                    ),
                    StatCard(
                      title: 'BMI Score',
                      value: profile?.bmi.toStringAsFixed(1) ?? '22.8',
                      subtitle: profile?.bmiCategory ?? 'Normal',
                      icon: Icons.monitor_weight_outlined,
                      iconColor: AppColors.purple,
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Today's Medication Tracker Section
            SectionHeader(
              title: "Today's Medication Tracker",
              actionText: 'View All Meds',
              onActionTap: () => context.go('/medications'),
            ),
            const SizedBox(height: 12),
            if (activeMeds.isEmpty)
              const EmptyState(
                icon: Icons.medication_outlined,
                title: 'No Active Medications',
                description: 'You currently have no active prescribed medications registered.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeMeds.length,
                itemBuilder: (context, index) {
                  final med = activeMeds[index];
                  return MedicationTrackerTile(
                    medication: med,
                    onToggle: () => medProvider.toggleTakenToday(med.id),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Recent Timeline History Preview
            SectionHeader(
              title: 'Recent Health Timeline',
              actionText: 'View Full Timeline',
              onActionTap: () => context.go('/history'),
            ),
            const SizedBox(height: 12),
            if (historyProvider.events.isEmpty)
              const EmptyState(
                icon: Icons.history_toggle_off,
                title: 'No Recent Events',
                description: 'Your health activity timeline is currently empty.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyProvider.events.take(4).length,
                itemBuilder: (context, index) {
                  final event = historyProvider.events[index];
                  final isLast = index == historyProvider.events.take(4).length - 1;
                  return TimelineTile(event: event, isLast: isLast);
                },
              ),
          ],
        ),
      ),

      // Quick Floating Actions
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.psychology, color: Colors.black),
        label: Text('Ask Claude AI', style: AppTypography.labelLarge.copyWith(color: Colors.black)),
        onPressed: () => context.go('/advisor'),
      ),
    );
  }
}
