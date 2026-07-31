import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class TimelineTile extends StatelessWidget {
  final HealthEvent event;
  final bool isLast;
  final VoidCallback? onDelete;

  const TimelineTile({
    super.key,
    required this.event,
    this.isLast = false,
    this.onDelete,
  });

  IconData get icon {
    switch (event.type) {
      case 'medication':
        return Icons.medication;
      case 'scan':
        return Icons.document_scanner;
      case 'vitals':
        return Icons.watch_sharp;
      case 'appointment':
        return Icons.calendar_today;
      case 'document':
        return Icons.file_present;
      default:
        return Icons.event;
    }
  }

  Color get color {
    switch (event.type) {
      case 'medication':
        return AppColors.primary;
      case 'scan':
        return AppColors.secondary;
      case 'vitals':
        return AppColors.purple;
      case 'appointment':
        return AppColors.warning;
      case 'document':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 16),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(event.date),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
