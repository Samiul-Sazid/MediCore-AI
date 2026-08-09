import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/doctor.dart';
import '../../providers/doctor_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  String? _selectedDay;
  String? _selectedDate;
  String? _selectedTime;
  String _reason = '';
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    if (widget.doctor.availableDays.isNotEmpty) {
      _selectedDay = widget.doctor.availableDays.first;
      _computeNextDate();
      _loadSlots();
    }
  }

  void _computeNextDate() {
    // Find the next occurrence of the selected day
    final dayMap = {'Mon': DateTime.monday, 'Tue': DateTime.tuesday, 'Wed': DateTime.wednesday, 'Thu': DateTime.thursday, 'Fri': DateTime.friday, 'Sat': DateTime.saturday, 'Sun': DateTime.sunday};
    final targetDay = dayMap[_selectedDay] ?? DateTime.monday;
    var date = DateTime.now();
    while (date.weekday != targetDay) {
      date = date.add(const Duration(days: 1));
    }
    _selectedDate = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadSlots() async {
    if (_selectedDay == null || _selectedDate == null) return;
    setState(() {
      _loadingSlots = true;
      _selectedTime = null;
    });

    final provider = Provider.of<DoctorProvider>(context, listen: false);
    final slots = await provider.getSlots(widget.doctor.id, date: _selectedDate!, day: _selectedDay!);

    if (mounted) {
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) return;

    setState(() => _booking = true);
    final provider = Provider.of<DoctorProvider>(context, listen: false);

    final success = await provider.bookAppointment(
      doctor: widget.doctor,
      appointmentDate: _selectedDate!,
      startTime: _selectedTime!,
      reason: _reason,
    );

    if (mounted) {
      setState(() => _booking = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Booking failed. Please try again.'), backgroundColor: AppColors.danger),
        );
        provider.clearError();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 20),
            Text('Appointment Confirmed!', style: AppTypography.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '${widget.doctor.name}\n$_selectedDate at $_selectedTime',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'View My Appointments',
              width: double.infinity,
              onPressed: () {
                Navigator.pop(context);
                context.go('/doctors/appointments');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/doctors');
              },
              child: const Text('Back to Doctors'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.go('/doctors'),
                ),
                const SizedBox(width: 8),
                Text('Doctor Profile', style: AppTypography.displaySmall),
              ],
            ),
            const SizedBox(height: 20),

            // Doctor Info Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: doc.photoUrl.isNotEmpty ? NetworkImage(doc.photoUrl) : null,
                        child: doc.photoUrl.isEmpty
                            ? Text(doc.name.split(' ').last[0], style: AppTypography.displaySmall.copyWith(color: AppColors.primary))
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: AppTypography.titleLarge),
                            const SizedBox(height: 4),
                            Text('${doc.specialty} • ${doc.subSpecialty}', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text(doc.hospital, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoTile(Icons.star, '${doc.rating}', '${doc.reviewCount} reviews'),
                      _infoTile(Icons.work_history, '${doc.experienceYears}', 'Years Exp.'),
                      _infoTile(Icons.payments, '\$${doc.consultationFee.toStringAsFixed(0)}', 'Consultation'),
                    ],
                  ),
                  if (doc.qualifications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.school, color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(doc.qualifications, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Available Days
            Text('Select Day', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: doc.availableDays.map((day) {
                final isSelected = _selectedDay == day;
                return ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cardBg,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.w600),
                  onSelected: (_) {
                    setState(() => _selectedDay = day);
                    _computeNextDate();
                    _loadSlots();
                  },
                );
              }).toList(),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              Text('Next available: $_selectedDate', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 24),

            // Time Slots
            Text('Select Time Slot', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _loadingSlots
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
                : _slots.isEmpty
                    ? GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('No time slots available for this day.', style: AppTypography.bodyMedium),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _slots.map((slot) {
                          final time = slot['start_time'] ?? '';
                          final isBooked = slot['is_booked'] == true;
                          final isSelected = _selectedTime == time;

                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: isBooked ? AppColors.danger.withValues(alpha: 0.1) : AppColors.cardBg,
                            labelStyle: TextStyle(
                              color: isBooked
                                  ? AppColors.textMuted
                                  : isSelected
                                      ? Colors.black
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              decoration: isBooked ? TextDecoration.lineThrough : null,
                            ),
                            onSelected: isBooked
                                ? null
                                : (_) => setState(() => _selectedTime = time),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 24),

            // Reason field
            Text('Reason for Visit (Optional)', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            TextField(
              maxLines: 2,
              onChanged: (v) => _reason = v,
              decoration: const InputDecoration(
                hintText: 'Describe your symptoms or reason for consultation...',
              ),
            ),
            const SizedBox(height: 32),

            // Book Button
            GradientButton(
              text: _booking ? 'Booking...' : 'Confirm Appointment',
              width: double.infinity,
              icon: Icons.check_circle_outline,
              onPressed: (_selectedTime != null && !_booking) ? _confirmBooking : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
