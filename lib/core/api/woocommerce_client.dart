import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/customer_info.dart';
import '../models/order_summary.dart';
import '../models/product.dart';
import '../models/product_variation.dart';

class WooCommerceClient {
  WooCommerceClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static int _requestCounter = 0;
  final Map<int, DateTime> _requestStartedAt = <int, DateTime>{};

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await _get('products/categories', query: {'per_page': '100'});
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int perPage = 20,
    String? orderBy,
    String? order,
  }) async {
    final query = <String, String>{
      'per_page': '$perPage',
      'page': '$page',
    };
    if (categoryId != null) query['category'] = '$categoryId';
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (orderBy != null) query['orderby'] = orderBy;
    if (order != null) query['order'] = order;

    final response = await _get('products', query: query);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> fetchAllProducts({
    int? categoryId,
    String? search,
    int perPage = 100,
    String? orderBy,
    String? order,
  }) async {
    final all = <Product>[];
    final seenIds = <int>{};
    var page = 1;

    while (true) {
      final batch = await fetchProducts(
        categoryId: categoryId,
        search: search,
        page: page,
        perPage: perPage,
        orderBy: orderBy,
        order: order,
      );

      for (final product in batch) {
        if (seenIds.add(product.id)) {
          all.add(product);
        }
      }

      if (batch.length < perPage) break;
      page++;
    }

    return all;
  }

  Future<Product> fetchProductById(int id) async {
    final response = await _get('products/$id');
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<int?> findVariationId(int productId) async {
    final response =
        await _get('products/$productId/variations', query: {'per_page': '1'});
    final list = jsonDecode(response.body) as List<dynamic>;
    if (list.isEmpty) return null;
    return (list.first as Map<String, dynamic>)['id'] as int?;
  }

  Future<List<ProductVariation>> fetchVariations(int productId) async {
    final response = await _get(
      'products/$productId/variations',
      query: {'per_page': '100'},
    );
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProductVariation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> applyCoupon({required String code, required double subtotal}) async {
    final response = await _get('coupons', query: {'code': code});
    final coupons = jsonDecode(response.body) as List<dynamic>;
    if (coupons.isEmpty) {
      throw Exception('Invalid coupon code');
    }
    final coupon = coupons.first as Map<String, dynamic>;
    final amount = double.tryParse(coupon['amount']?.toString() ?? '0') ?? 0;
    final discountType = coupon['discount_type'] as String? ?? '';
    if (discountType == 'percent') {
      final discounted = subtotal - (subtotal * amount / 100);
      return discounted.toStringAsFixed(2);
    }
    return (subtotal - amount).clamp(0, double.infinity).toStringAsFixed(2);
  }

  Future<int> createOrder({
    required CustomerInfo customer,
    required List<Map<String, dynamic>> lineItems,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Cash on delivery',
    List<Map<String, dynamic>> couponLines = const [],
  }) async {
    final response = await _post('orders', body: {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': false,
      'billing': customer.toWooAddressJson(),
      'shipping': customer.toWooAddressJson(),
      'line_items': lineItems,
      'coupon_lines': couponLines,
    });
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as int? ?? 0;
  }

  Future<List<OrderSummary>> fetchOrdersByCustomer(int customerId) async {
    final response = await _get(
      'orders',
      query: {'customer': '$customerId', 'per_page': '20'},
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? query}) async {
    final requestId = ++_requestCounter;
    final uri = _buildUri(endpoint, query: query);
    _logRequest(
      requestId: requestId,
      method: 'GET',
      uri: uri,
      query: query,
    );
    final response = await _httpClient.get(uri);
    _logResponse(requestId: requestId, response: response);
    _ensureSuccess(response);
    return response;
  }

  Future<http.Response> _post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final requestId = ++_requestCounter;
    final uri = _buildUri(endpoint);
    _logRequest(
      requestId: requestId,
      method: 'POST',
      uri: uri,
      body: body,
    );
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _logResponse(requestId: requestId, response: response);
    _ensureSuccess(response);
    return response;
  }

  Uri _buildUri(String endpoint, {Map<String, String>? query}) {
    final fullQuery = <String, String>{
      'consumer_key': AppConfig.consumerKey,
      'consumer_secret': AppConfig.consumerSecret,
      ...?query,
    };
    return Uri.parse('${AppConfig.baseUrl}/wp-json/wc/v3/$endpoint')
        .replace(queryParameters: fullQuery);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode && !AppConfig.wooApiVerboseLogFull) {
        final path = response.request?.url.path ?? '';
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        debugPrint('Woo API error ${response.statusCode} $path: $snippet');
      }
      throw Exception('Request failed (${response.statusCode}): ${response.body}');
    }
  }

  void _logRequest({
    required int requestId,
    required String method,
    required Uri uri,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) {
    final shouldLog = kDebugMode || AppConfig.wooApiLogEnabled;
    if (!shouldLog) return;
    _requestStartedAt[requestId] = DateTime.now();
    final stamp = _nowStamp();
    final fullVerbose = AppConfig.wooApiVerboseLogFull;
    if (fullVerbose) {
      debugPrint('========== API REQUEST #$requestId [$stamp] ==========');
      debugPrint('METHOD: $method');
      debugPrint('URI: ${_redactUri(uri)}');
      if (query != null && query.isNotEmpty) {
        debugPrint('QUERY:\n${_prettyJson(query)}');
      }
      if (body != null) {
        debugPrint('BODY:\n${_prettyJson(body)}');
      }
      debugPrint('============================================');
    } else {
      // Path only — query contains consumer keys; do not log full [Uri].
      debugPrint('[$stamp] Woo > #$requestId $method ${uri.path}');
      if (body != null) {
        final len = jsonEncode(body).length;
        debugPrint('[$stamp] Woo   JSON body: $len chars');
      }
    }
  }

  void _logResponse({
    required int requestId,
    required http.Response response,
  }) {
    final shouldLog = kDebugMode || AppConfig.wooApiLogEnabled;
    if (!shouldLog) return;
    final u = response.request?.url;
    final path = u?.path ?? '';
    final stamp = _nowStamp();
    final startedAt = _requestStartedAt.remove(requestId);
    final elapsedMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;
    final elapsedLabel = elapsedMs == null ? '' : ' (${elapsedMs}ms)';

    if (AppConfig.wooApiVerboseLogFull) {
      debugPrint('========== API RESPONSE #$requestId [$stamp]$elapsedLabel =========');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('URL: ${u == null ? '(unknown)' : _redactUri(u)}');
      debugPrint('RESPONSE:\n${_prettyResponse(response.body)}');
      debugPrint('============================================');
    } else {
      final n = response.body.length;
      debugPrint('[$stamp] Woo < #$requestId ${response.statusCode} $n bytes $path$elapsedLabel');
    }
  }

  String _prettyResponse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '<empty>';
    try {
      final decoded = jsonDecode(trimmed);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  String _prettyJson(Object data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Hides [consumer_key] / [consumer_secret] query params in log output.
  Uri _redactUri(Uri uri) {
    if (!uri.hasQuery) return uri;
    final q = Map<String, String>.from(uri.queryParameters);
    if (q.containsKey('consumer_key')) q['consumer_key'] = '***';
    if (q.containsKey('consumer_secret')) q['consumer_secret'] = '***';
    return uri.replace(queryParameters: q);
  }

  String _nowStamp() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.${three(now.millisecond)}';
  }
}
