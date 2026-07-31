import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SearchChipField extends StatefulWidget {
  final List<String> selectedChips;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String hintText;
  final List<String> suggestions;

  const SearchChipField({
    super.key,
    required this.selectedChips,
    required this.onAdd,
    required this.onRemove,
    this.hintText = 'Type symptom and press Enter...',
    this.suggestions = const [],
  });

  @override
  State<SearchChipField> createState() => _SearchChipFieldState();
}

class _SearchChipFieldState extends State<SearchChipField> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: _submit,
            ),
          ),
        ),
        if (widget.selectedChips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedChips.map((chip) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => widget.onRemove(chip),
                      child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Suggested Tags:', style: AppTypography.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.suggestions
                .where((s) => !widget.selectedChips.contains(s))
                .map((s) {
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.cardBg,
                onPressed: () => widget.onAdd(s),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
