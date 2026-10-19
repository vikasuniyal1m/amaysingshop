import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

class CartOrderSummary extends ConsumerWidget {
  const CartOrderSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final shipping = ref.watch(shippingProvider);
    final tax = ref.watch(taxProvider);
    final discount = ref.watch(couponDiscountProvider);
    final total = ref.watch(cartGrandTotalProvider);

    return Column(
      children: [
        _SummaryRow(label: 'Subtotal', value: subtotal),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Shipping Cost', value: shipping),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Tax', value: tax),
        if (discount > 0) ...[
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Discount',
            value: -discount,
            valueColor: Colors.green.shade700,
          ),
        ],
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Total',
          value: total,
          labelBold: true,
          valueBold: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelBold = false,
    this.valueBold = false,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool labelBold;
  final bool valueBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final formatted = value < 0
        ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelBold ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 16,
            fontWeight: labelBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          formatted,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
