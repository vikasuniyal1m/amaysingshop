import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/cart_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

class CartItemCard extends ConsumerWidget {
  const CartItemCard({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitPrice = item.unitPrice ?? item.product.numericPrice;
    final size = _attributeValue(item.selectedAttributes, 'size');
    final color = _attributeValue(item.selectedAttributes, 'color');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.product.images.isNotEmpty
                  ? Image.network(
                      item.product.images.first,
                      fit: BoxFit.cover,
                    )
                  : const ColoredBox(
                      color: AppTheme.surfaceGrey,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppTheme.navInactive,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (size != null) _AttributeLabel(label: 'Size', value: size),
                          if (color != null)
                            _AttributeLabel(label: 'Color', value: color),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QtyCircleButton(
                          icon: Icons.remove,
                          onTap: () => ref.read(cartProvider.notifier).decrement(
                                item.product.id,
                                variationId: item.variationId,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _QtyCircleButton(
                          icon: Icons.add,
                          onTap: () => ref.read(cartProvider.notifier).increment(
                                item.product.id,
                                variationId: item.variationId,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _attributeValue(Map<String, String> attrs, String key) {
    for (final entry in attrs.entries) {
      final name = entry.key.toLowerCase();
      if (name.contains(key) || name.replaceAll('pa_', '').contains(key)) {
        final v = entry.value.trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }
}

class _AttributeLabel extends StatelessWidget {
  const _AttributeLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const TextSpan(
            text: ' - ',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyCircleButton extends StatelessWidget {
  const _QtyCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.brandActive,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 14, color: AppTheme.textLight),
        ),
      ),
    );
  }
}
