import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/customer_info.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.payPal = false});

  final bool payPal;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postcode = TextEditingController();
  final _country = TextEditingController(text: 'US');
  final _coupon = TextEditingController();
  String _shippingMethod = 'flat_rate';
  String _paymentMethod = 'cod';
  String _paymentTitle = 'Cash on delivery';
  int? _lastOrderId;

  @override
  void initState() {
    super.initState();
    if (widget.payPal) {
      _paymentMethod = 'paypal';
      _paymentTitle = 'PayPal';
    }
  }

  static const _paymentOptions = [
    ('cod', 'Cash on Delivery', Icons.payments_outlined),
    ('paypal', 'PayPal', Icons.paypal_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartGrandTotalProvider);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 8),
              const Text(
                'Choose Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              const SizedBox(height: 14),
              Row(
                children: _paymentOptions.map((opt) {
                  final isSelected = _paymentMethod == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _paymentMethod = opt.$1;
                        _paymentTitle = opt.$2;
                      }),
                      child: Container(
                        width: 80,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(opt.$3, size: 28, color: isSelected ? Colors.black : Colors.grey.shade500),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Shipping Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildField(_firstName, 'First name')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_lastName, 'Last name')),
                ],
              ),
              _buildField(_email, 'Email'),
              _buildField(_phone, 'Phone'),
              _buildField(_address, 'Address'),
              Row(
                children: [
                  Expanded(child: _buildField(_city, 'City')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_state, 'State')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildField(_postcode, 'Postcode')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_country, 'Country code')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _shippingMethod,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(value: 'flat_rate', child: Text('Flat rate shipping')),
                      DropdownMenuItem(value: 'free_shipping', child: Text('Free shipping')),
                      DropdownMenuItem(value: 'local_pickup', child: Text('Local pickup')),
                    ],
                    onChanged: (value) => setState(() => _shippingMethod = value ?? 'flat_rate'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_coupon, 'Promo or Voucher code', required: false),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D2D2D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text(
                    'Complete Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_lastOrderId != null)
                Text(
                  'Last successful order: #$_lastOrderId',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: (value) {
          if (!required) return null;
          if (value == null || value.trim().isEmpty) return '$label is required';
          return null;
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6D2D2D), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final total = ref.read(cartGrandTotalProvider);
    final customer = CustomerInfo(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address1: _address.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postcode: _postcode.text.trim(),
      country: _country.text.trim(),
    );
    try {
      final orderId = await ref.read(
        checkoutProvider(
          CheckoutPayload(
            customer: customer,
            paymentMethod: _paymentMethod,
            paymentTitle: _paymentTitle,
            couponCode: _coupon.text.trim(),
          ),
        ).future,
      );
      final itemCount = ref.read(cartProvider).fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
      ref.read(cartProvider.notifier).clear();
      if (!context.mounted) return;
      setState(() => _lastOrderId = orderId);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            total: total,
            itemCount: itemCount,
            paymentTitle: _paymentTitle,
            shippingMethod: _shippingMethod,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
