import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

class CartCouponField extends ConsumerStatefulWidget {
  const CartCouponField({super.key});

  @override
  ConsumerState<CartCouponField> createState() => _CartCouponFieldState();
}

class _CartCouponFieldState extends ConsumerState<CartCouponField> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    final appliedCode = ref.read(appliedCouponProvider);
    if (appliedCode == code) {
      setState(() {
        _message = 'Coupon already applied';
        _success = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final subtotal = ref.read(cartSubtotalProvider);
      final discountedTotal = await ref.read(wooClientProvider).applyCoupon(
            code: code,
            subtotal: subtotal,
          );
      final discount = subtotal - double.parse(discountedTotal);
      ref.read(appliedCouponProvider.notifier).state = code;
      ref.read(couponDiscountProvider.notifier).state = discount;
      setState(() {
        _message = 'Coupon applied';
        _success = true;
        _loading = false;
      });
    } catch (_) {
      ref.read(appliedCouponProvider.notifier).state = '';
      ref.read(couponDiscountProvider.notifier).state = 0;
      setState(() {
        _message = 'Invalid coupon code';
        _success = false;
        _loading = false;
      });
    }
  }

  void _removeCoupon() {
    ref.read(appliedCouponProvider.notifier).state = '';
    ref.read(couponDiscountProvider.notifier).state = 0;
    _controller.clear();
    setState(() {
      _message = null;
      _success = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasApplied = ref.watch(appliedCouponProvider).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 24,
                color: hasApplied ? AppTheme.brandActive : Colors.green.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !hasApplied,
                  decoration: const InputDecoration(
                    hintText: 'Enter Coupon Code',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyCoupon(),
                ),
              ),
              Material(
                color: AppTheme.brandActive,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _loading
                      ? null
                      : (hasApplied ? _removeCoupon : _applyCoupon),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textLight,
                            ),
                          )
                        : Icon(
                            hasApplied
                                ? Icons.close
                                : Icons.chevron_right,
                            color: AppTheme.textLight,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _message!,
              style: TextStyle(
                fontSize: 12,
                color: _success ? Colors.green.shade700 : Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
