import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

class DocumentCard extends StatelessWidget {
  final DocumentRecord document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  IconData get fileIcon {
    final t = document.fileType.toLowerCase();
    if (t == 'pdf') return Icons.picture_as_pdf;
    if (t == 'jpg' || t == 'png' || t == 'jpeg') return Icons.image;
    return Icons.insert_drive_file;
  }

  Color get iconColor {
    final t = document.fileType.toLowerCase();
    if (t == 'pdf') return AppColors.danger;
    if (t == 'jpg' || t == 'png' || t == 'jpeg') return AppColors.info;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fileIcon, color: iconColor, size: 24),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const Spacer(),
          Text(
            document.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  document.category,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
              Text(
                document.formattedSize,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateFormat.format(document.uploadedAt),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
