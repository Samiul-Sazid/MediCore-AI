import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class MedicationTrackerTile extends StatelessWidget {
  final Medication medication;
  final VoidCallback onToggle;

  const MedicationTrackerTile({
    super.key,
    required this.medication,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final taken = medication.takenToday();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: taken ? AppColors.success.withValues(alpha: 0.08) : AppColors.cardBg,
      borderColor: taken ? AppColors.success.withValues(alpha: 0.3) : AppColors.cardBorder,
      child: Row(
        children: [
          Checkbox(
            value: taken,
            activeColor: AppColors.success,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.drugName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    decoration: taken ? TextDecoration.lineThrough : null,
                    color: taken ? AppColors.textMuted : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${medication.dosage} • ${medication.whenToTake}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                medication.frequency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: AppColors.info),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
