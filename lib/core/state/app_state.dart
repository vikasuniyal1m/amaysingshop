import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_service.dart';
import '../api/woocommerce_client.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/customer_info.dart';
import '../models/order_summary.dart';
import '../models/product.dart';

class AppState extends ChangeNotifier {
  AppState({
    WooCommerceClient? wooClient,
    AuthService? authService,
  })  : _wooClient = wooClient ?? WooCommerceClient(),
        _authService = authService ?? AuthService() {
    _restoreSession();
  }

  final WooCommerceClient _wooClient;
  final AuthService _authService;

  final List<CartItem> _cartItems = [];
  final List<ProductCategory> _categories = [];
  final List<Product> _products = [];
  final List<OrderSummary> _orders = [];

  String? _authToken;
  int? _customerId;
  String? _email;
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  List<ProductCategory> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  List<OrderSummary> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authToken != null && _customerId != null;
  String get userEmail => _email ?? '';
  double get subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> loadCategories() async {
    await _guard(() async {
      final data = await _wooClient.fetchCategories();
      _categories
        ..clear()
        ..addAll(data.where((e) => e.id != 0));
    });
  }

  Future<void> loadProducts({
    int? categoryId,
    String? search,
    String orderBy = 'popularity',
  }) async {
    await _guard(() async {
      final data = await _wooClient.fetchProducts(
        categoryId: categoryId,
        search: search,
        orderBy: orderBy,
      );
      _products
        ..clear()
        ..addAll(data);
    });
  }

  void addToCart(Product product, {int quantity = 1, int? variationId}) {
    final index = _cartItems.indexWhere((e) =>
        e.product.id == product.id && (e.variationId ?? 0) == (variationId ?? 0));
    if (index == -1) {
      _cartItems.add(
        CartItem(product: product, quantity: quantity, variationId: variationId),
      );
    } else {
      final existing = _cartItems[index];
      _cartItems[index] = existing.copyWith(quantity: existing.quantity + quantity);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((e) => e.product.id == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  Future<String> applyCoupon(String code) async {
    return _wooClient.applyCoupon(code: code, subtotal: subtotal);
  }

  Future<int> placeOrder(CustomerInfo customer, {String? couponCode}) async {
    int? preparedVariationId;
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }
    final firstVariable = _cartItems
        .where((item) => item.product.hasVariants && item.variationId == null)
        .firstOrNull;
    if (firstVariable != null) {
      preparedVariationId =
          await _wooClient.findVariationId(firstVariable.product.id);
    }

    final lineItems = _cartItems
        .map((item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              if (item.variationId != null ||
                  (preparedVariationId != null &&
                      item.product.id == firstVariable?.product.id))
                'variation_id': item.variationId ?? preparedVariationId,
            })
        .toList();

    final orderId = await _wooClient.createOrder(
      customer: customer,
      lineItems: lineItems,
      couponLines: couponCode == null || couponCode.isEmpty
          ? []
          : [
              {'code': couponCode}
            ],
    );
    _cartItems.clear();
    notifyListeners();
    return orderId;
  }

  Future<void> login(String username, String password) async {
    await _guard(() async {
      final session =
          await _authService.login(username: username, password: password);
      _authToken = session.token;
      _customerId = session.userId;
      _email = session.email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', session.token);
      await prefs.setInt('customer_id', session.userId);
      await prefs.setString('email', session.email);
    });
  }

  Future<void> register(String username, String email, String password) async {
    await _guard(() async {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
    });
  }

  Future<void> loadOrders() async {
    if (_customerId == null) return;
    await _guard(() async {
      final data = await _wooClient.fetchOrdersByCustomer(_customerId!);
      _orders
        ..clear()
        ..addAll(data);
    });
  }

  Future<void> logout() async {
    _authToken = null;
    _customerId = null;
    _email = null;
    _orders.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('customer_id');
    await prefs.remove('email');
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _customerId = prefs.getInt('customer_id');
    _email = prefs.getString('email');
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() callback) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await callback();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null || scope.notifier == null) {
      throw Exception('AppStateScope is missing');
    }
    return scope.notifier!;
  }
}
