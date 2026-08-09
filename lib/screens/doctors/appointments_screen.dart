import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/doctor_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).loadAppointments();
    });
  }

  void _confirmCancel(String appointmentId, String doctorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Appointment?'),
        content: Text('Are you sure you want to cancel your appointment with $doctorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<DoctorProvider>(context, listen: false).cancelAppointment(appointmentId);
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DoctorProvider>(context);
    final appointments = docProvider.appointments;

    final upcoming = appointments.where((a) => a['status'] == 'confirmed' || a['status'] == 'pending').toList();
    final past = appointments.where((a) => a['status'] == 'completed' || a['status'] == 'cancelled').toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + Title
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.go('/doctors'),
                ),
                const SizedBox(width: 8),
                Text('My Appointments', style: AppTypography.displaySmall),
              ],
            ),
            const SizedBox(height: 20),

            if (docProvider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary))),

            if (!docProvider.isLoading && appointments.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 56),
                    const SizedBox(height: 16),
                    Text('No appointments yet', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text('Book your first appointment from the doctor directory.', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Find a Doctor',
                      icon: Icons.search,
                      onPressed: () => context.go('/doctors'),
                    ),
                  ],
                ),
              ),
            ],

            // Upcoming Section
            if (upcoming.isNotEmpty) ...[
              _sectionHeader('Upcoming', upcoming.length, AppColors.primary),
              const SizedBox(height: 12),
              ...upcoming.map((apt) => _buildAppointmentCard(apt, isUpcoming: true)),
              const SizedBox(height: 24),
            ],

            // Past Section
            if (past.isNotEmpty) ...[
              _sectionHeader('Past', past.length, AppColors.textMuted),
              const SizedBox(height: 12),
              ...past.map((apt) => _buildAppointmentCard(apt, isUpcoming: false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text('$title ($count)', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt, {required bool isUpcoming}) {
    final status = apt['status'] ?? 'pending';
    final doctorName = apt['doctor_name'] ?? 'Unknown Doctor';
    final specialty = apt['doctor_specialty'] ?? '';
    final hospital = apt['doctor_hospital'] ?? '';
    final date = apt['appointment_date'] ?? '';
    final startTime = apt['start_time'] ?? '';
    final endTime = apt['end_time'] ?? '';
    final id = apt['id'].toString();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = AppColors.primary;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.help_outline;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    if (specialty.isNotEmpty)
                      Text(specialty, style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                    if (hospital.isNotEmpty)
                      Text(hospital, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Text(date, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Text('$startTime - $endTime', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          if (isUpcoming && status != 'cancelled') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 16),
                label: const Text('Cancel', style: TextStyle(color: AppColors.danger)),
                onPressed: () => _confirmCancel(id, doctorName),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
