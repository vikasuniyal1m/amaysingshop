import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../checkout/presentation/checkout_screen.dart';
import 'widgets/cart_coupon_field.dart';
import 'widgets/cart_header.dart';
import 'widgets/cart_item_card.dart';
import 'widgets/cart_order_summary.dart';
import 'widgets/empty_cart_view.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const _horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: EmptyCartView(
          onBack: () => ref.read(selectedBottomTabProvider.notifier).state = 0,
          onExploreCategories: () =>
              ref.read(selectedBottomTabProvider.notifier).state = 1,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(
              onBack: () => ref.read(selectedBottomTabProvider.notifier).state = 0,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                0,
                _horizontalPadding,
                12,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    ref.read(cartProvider.notifier).clear();
                    ref.read(appliedCouponProvider.notifier).state = '';
                    ref.read(couponDiscountProvider.notifier).state = 0;
                  },
                  child: const Text(
                    'Remove All',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  0,
                  _horizontalPadding,
                  12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CartItemCard(item: items[index]),
                  );
                },
              ),
            ),
            _CartBottomPanel(
              onCheckout: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed bottom: totals, coupon, checkout (product list scrolls above).
class _CartBottomPanel extends StatelessWidget {
  const _CartBottomPanel({required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CartOrderSummary(),
              const SizedBox(height: 16),
              const CartCouponField(),
              const SizedBox(height: 16),
              Material(
                color: AppTheme.brandActive,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  onTap: onCheckout,
                  borderRadius: BorderRadius.circular(100),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Checkout',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
