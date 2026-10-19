import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchFilterChip extends StatelessWidget {
  const SearchFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.showChevron = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandActive : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              if (label.isNotEmpty) const SizedBox(width: 4),
            ],
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.textLight : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: selected ? AppTheme.textLight : AppTheme.textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
