import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    required this.itemCount,
    required this.paymentTitle,
    required this.shippingMethod,
  });

  final int orderId;
  final double total;
  final int itemCount;
  final String paymentTitle;
  final String shippingMethod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D2D2D), Color(0xFFB67B5B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D2D2D).withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 62),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Order Placed Successfully!',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F3F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Achievement unlocked: Smart Shopper',
                          style: TextStyle(
                            color: Color(0xFF6D2D2D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFE5E1)),
                      ),
                      child: Column(
                        children: [
                          _line('Order ID', '#$orderId', bold: true),
                          _line('Items', '$itemCount'),
                          _line('Payment', paymentTitle),
                          _line('Shipping', shippingMethod),
                          const Divider(height: 22),
                          _line('Total Paid', '\$${total.toStringAsFixed(2)}', bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F3F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_offer_outlined, color: Color(0xFF6D2D2D)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keep shopping to unlock special offers and member-only deals.',
                              style: TextStyle(color: Color(0xFF6D2D2D), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D2D2D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    ref.read(selectedBottomTabProvider.notifier).state = 0;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Explore More Products'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _line(String key, String value, {bool bold = false}) {
  final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(key, style: style), Text(value, style: style)],
    ),
  );
}
