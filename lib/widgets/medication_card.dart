import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onToggleTaken;
  final VoidCallback? onStop;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onToggleTaken,
    this.onStop,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = medication.isActive;
    final takenToday = medication.takenToday();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pale Mint Container Icon Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_liquid_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            medication.drugName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.surfaceLight : AppColors.alertGradient.first,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'STOPPED',
                            style: AppTypography.labelSmall.copyWith(
                              color: isActive ? AppColors.primary : AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.dosage} • ${medication.frequency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (medication.whenToTake.isNotEmpty)
                      Text(
                        'Schedule: ${medication.whenToTake}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (medication.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Notes: ${medication.notes}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isActive && onToggleTaken != null)
                Expanded(
                  child: InkWell(
                    onTap: onToggleTaken,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            takenToday ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: takenToday ? AppColors.primary : AppColors.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              takenToday ? 'Dose Taken Today' : 'Mark Dose Taken',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: takenToday ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (!isActive)
                Expanded(
                  child: Text(
                    'Reason: ${medication.stopReason.isEmpty ? "Discontinued" : medication.stopReason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive && onStop != null)
                    IconButton(
                      icon: const Icon(Icons.pause_circle_outline, color: AppColors.warning, size: 22),
                      tooltip: 'Stop Medication',
                      onPressed: onStop,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                      tooltip: 'Delete Record',
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
