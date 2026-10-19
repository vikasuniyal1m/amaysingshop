import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Figma-style pill row: label left, value + chevron right.
class ProductDetailSelectorRow extends StatelessWidget {
  const ProductDetailSelectorRow({
    super.key,
    required this.label,
    required this.value,
    this.leading,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: AppTheme.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma quantity row with brand +/- circles.
class ProductDetailQuantityRow extends StatelessWidget {
  const ProductDetailQuantityRow({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.canDecrement = true,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _QtyCircleButton(
            icon: Icons.remove,
            enabled: canDecrement,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _QtyCircleButton(
            icon: Icons.add,
            enabled: canIncrement,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyCircleButton extends StatelessWidget {
  const _QtyCircleButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppTheme.brandActive : AppTheme.navInactive,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: AppTheme.textLight),
        ),
      ),
    );
  }
}
