import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/woocommerce_client.dart';
import '../search/product_search_engine.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/recent_view_context.dart';
import '../models/customer_info.dart';
import '../models/product.dart';
import '../models/product_variation.dart';

final wooClientProvider = Provider<WooCommerceClient>((ref) {
  return WooCommerceClient();
});

final productSearchEngineProvider = Provider<ProductSearchEngine>((ref) {
  return ProductSearchEngine(ref.read(wooClientProvider));
});

final selectedBottomTabProvider = StateProvider<int>((ref) => 0);

final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final orderByProvider = StateProvider<String>((ref) => 'popularity');
final inStockOnlyProvider = StateProvider<bool>((ref) => false);
final minPriceProvider = StateProvider<double>((ref) => 0);
final maxPriceProvider = StateProvider<double>((ref) => 500);
final searchOnSaleOnlyProvider = StateProvider<bool>((ref) => false);
final searchGenderCategoryIdProvider = StateProvider<int?>((ref) => null);
final lastViewedProductIdProvider = StateProvider<int?>((ref) => null);

final recentlyViewedIdsProvider = Provider<List<int>>((ref) {
  return ref.watch(recentViewContextProvider).productIds;
});

final recentViewContextProvider =
    StateNotifierProvider<RecentViewContextNotifier, RecentViewContext>((ref) {
  return RecentViewContextNotifier();
});

class RecentViewContextNotifier extends StateNotifier<RecentViewContext> {
  RecentViewContextNotifier() : super(const RecentViewContext()) {
    _load();
  }

  static const _idsKey = 'recently_viewed_product_ids';
  static const _categoriesKey = 'recent_view_category_ids';
  static const _relatedKey = 'recent_view_related_ids';
  static const _maxItems = 10;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final disk = RecentViewContext(
      productIds: _parseIdList(prefs.getStringList(_idsKey)).take(_maxItems).toList(),
      categoryIds: _parseIdSet(prefs.getStringList(_categoriesKey)),
      relatedIds: _parseIdSet(prefs.getStringList(_relatedKey)),
    );
    if (disk.isEmpty) return;

    if (state.isEmpty) {
      state = disk;
      return;
    }

    // Session tracking may have run before disk hydration — merge, never wipe.
    state = RecentViewContext(
      productIds: state.productIds,
      categoryIds: {...state.categoryIds, ...disk.categoryIds},
      relatedIds: {...state.relatedIds, ...disk.relatedIds},
    );
  }

  static List<int> _parseIdList(List<String>? raw) {
    return (raw ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
  }

  static Set<int> _parseIdSet(List<String>? raw) {
    return _parseIdList(raw).toSet();
  }

  Future<void> trackProduct({
    required int productId,
    required List<int> categoryIds,
    required List<int> relatedIds,
  }) async {
    if (productId <= 0) return;

    final updatedIds = [
      productId,
      ...state.productIds.where((id) => id != productId),
    ].take(_maxItems).toList();

    final updatedCategories = {
      ...state.categoryIds,
      ...categoryIds.where((id) => id > 0),
    };
    final updatedRelated = {
      ...state.relatedIds,
      ...relatedIds.where((id) => id > 0 && id != productId),
    };

    state = RecentViewContext(
      productIds: updatedIds,
      categoryIds: updatedCategories,
      relatedIds: updatedRelated,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _idsKey,
      updatedIds.map((id) => id.toString()).toList(),
    );
    await prefs.setStringList(
      _categoriesKey,
      updatedCategories.map((id) => id.toString()).toList(),
    );
    await prefs.setStringList(
      _relatedKey,
      updatedRelated.map((id) => id.toString()).toList(),
    );
  }

  Future<void> addProductId(int productId) async {
    await trackProduct(
      productId: productId,
      categoryIds: const [],
      relatedIds: const [],
    );
  }
}

int _recommendedScoreLocal(Product product, RecentViewContext context) {
  if (context.productIds.contains(product.id)) return 300;
  if (context.relatedIds.contains(product.id)) return 220;
  if (product.categoryIds.any(context.categoryIds.contains)) return 140;
  return product.totalSales.clamp(0, 30);
}

final recentlyViewedProductsProvider =
    FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(recentlyViewedIdsProvider);
  if (ids.isEmpty) return const <Product>[];
  final client = ref.read(wooClientProvider);
  final products = <Product>[];
  for (final id in ids.take(5)) {
    try {
      products.add(await client.fetchProductById(id));
    } catch (_) {}
  }
  return products;
});

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super(const []) {
    _load();
  }

  static const _key = 'recent_searches';
  static const _maxItems = 5;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((e) => e != trimmed)].take(_maxItems).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> remove(String query) async {
    final updated = state.where((e) => e != query).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Lightweight category list for search (no per-category image API calls).
final catalogCategoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return ref.read(wooClientProvider).fetchCategories();
});

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final client = ref.read(wooClientProvider);
  final categories = await client.fetchCategories();

  final enriched = await Future.wait(
    categories.map((cat) async {
      if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) return cat;
      try {
        final products = await client.fetchProducts(
          categoryId: cat.id,
          page: 1,
          perPage: 1,
        );
        if (products.isNotEmpty && products.first.images.isNotEmpty) {
          return ProductCategory(
            id: cat.id,
            name: cat.name,
            slug: cat.slug,
            parentId: cat.parentId,
            count: cat.count,
            imageUrl: products.first.images.first,
          );
        }
      } catch (_) {}
      return cat;
    }),
  );

  return enriched;
});

final rootCategoriesProvider = Provider<List<ProductCategory>>((ref) {
  final all = ref.watch(categoriesProvider).valueOrNull ?? const <ProductCategory>[];
  return all.where((e) => e.parentId == 0).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

final subCategoriesProvider =
    Provider.family<List<ProductCategory>, int>((ref, parentId) {
  final all = ref.watch(categoriesProvider).valueOrNull ?? const <ProductCategory>[];
  return all.where((e) => e.parentId == parentId).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Paginated product list for Home (matches website browsing page-by-page).
final homeProductsProvider =
    StateNotifierProvider<HomeProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return HomeProductsNotifier(ref);
});

class HomeProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  HomeProductsNotifier(this._ref) : super(const AsyncValue.loading()) {
    void onFilterChanged<T>(T? previous, T next) {
      if (previous != next) refresh();
    }

    _ref.listen(selectedCategoryProvider, onFilterChanged);
    _ref.listen(searchQueryProvider, onFilterChanged);
    _ref.listen(orderByProvider, onFilterChanged);
    _ref.listen(inStockOnlyProvider, onFilterChanged);
    _ref.listen(minPriceProvider, onFilterChanged);
    _ref.listen(maxPriceProvider, onFilterChanged);
    _ref.listen(searchOnSaleOnlyProvider, onFilterChanged);
    _ref.listen(searchGenderCategoryIdProvider, onFilterChanged);
    refresh();
  }

  final Ref _ref;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _refreshGen = 0;
  static const int _perPage = 20;

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    _loadingMore = false;
    final gen = ++_refreshGen;
    state = const AsyncValue.loading();
    try {
      final list = await _fetchPage(1);
      if (gen != _refreshGen) return;
      state = AsyncValue.data(list);
      _hasMore = list.length >= _perPage;
    } catch (e, st) {
      if (gen != _refreshGen) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Product>> _fetchPage(int page) async {
    final orderBy = _ref.read(orderByProvider);
    String? apiOrderBy;
    if (orderBy == 'popularity') apiOrderBy = 'popularity';
    if (orderBy == 'rating') apiOrderBy = 'rating';
    if (orderBy == 'date') apiOrderBy = 'date';
    if (orderBy == 'price') apiOrderBy = 'price';
    if (orderBy == 'price-desc') apiOrderBy = 'price';

    final searchQuery = _ref.read(searchQueryProvider).trim();
    final apiOrder = orderBy == 'price-desc' ? 'desc' : null;

    if (searchQuery.isNotEmpty) {
      if (page > 1) {
        final products = await _ref.read(wooClientProvider).fetchProducts(
              categoryId: _ref.read(searchGenderCategoryIdProvider),
              search: searchQuery,
              page: page,
              perPage: _perPage,
              orderBy: apiOrderBy,
              order: apiOrder,
            );
        return _applyLocalFilters(products);
      }

      final categories =
          _ref.read(catalogCategoriesProvider).valueOrNull ??
          _ref.read(categoriesProvider).valueOrNull ??
          const <ProductCategory>[];

      final products = await _ref.read(productSearchEngineProvider).search(
            query: searchQuery,
            categories: categories,
            orderBy: apiOrderBy,
            order: apiOrder,
            viewContext: _ref.read(recentViewContextProvider),
          );
      return _applyLocalFilters(products);
    }

    final products = await _ref.read(wooClientProvider).fetchProducts(
          categoryId: _ref.read(selectedCategoryProvider),
          page: page,
          perPage: _perPage,
          orderBy: apiOrderBy,
          order: apiOrder,
        );
    return _applyLocalFilters(products);
  }

  List<Product> _applyLocalFilters(List<Product> products) {
    final orderBy = _ref.read(orderByProvider);
    final inStockOnly = _ref.read(inStockOnlyProvider);
    final onSaleOnly = _ref.read(searchOnSaleOnlyProvider);
    final minPrice = _ref.read(minPriceProvider);
    final maxPrice = _ref.read(maxPriceProvider);

    var filtered = List<Product>.from(products);

    if (inStockOnly) {
      filtered = filtered.where((p) => p.inStock).toList();
    }

    if (onSaleOnly) {
      filtered = filtered.where((p) => p.onSale).toList();
    }

    if (minPrice > 0 || maxPrice < 500) {
      filtered = filtered.where((p) {
        final price = p.numericPrice;
        if (price <= 0) return true;
        return price >= minPrice && price <= maxPrice;
      }).toList();
    }

    final isSearch = _ref.read(searchQueryProvider).trim().isNotEmpty;

    switch (orderBy) {
      case 'price':
        filtered.sort((a, b) => a.numericPrice.compareTo(b.numericPrice));
        break;
      case 'price-desc':
        filtered.sort((a, b) => b.numericPrice.compareTo(a.numericPrice));
        break;
      case 'date':
        break;
      case 'popularity':
      default:
        if (!isSearch) {
          final context = _ref.read(recentViewContextProvider);
          filtered.sort((a, b) {
            final rec = _recommendedScoreLocal(b, context)
                .compareTo(_recommendedScoreLocal(a, context));
            if (rec != 0) return rec;
            return b.totalSales.compareTo(a.totalSales);
          });
        }
        break;
    }

    return filtered;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final gen = _refreshGen;
    _loadingMore = true;
    final requestPage = _page + 1;
    try {
      final more = await _fetchPage(requestPage);
      if (gen != _refreshGen) return;
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      _page = requestPage;
      state = AsyncValue.data([...current, ...more]);
      _hasMore = more.length >= _perPage;
    } catch (e, st) {
      if (gen != _refreshGen) return;
      state = AsyncValue.error(e, st);
    } finally {
      if (gen == _refreshGen) {
        _loadingMore = false;
      }
    }
  }

  bool get hasMore => _hasMore;
}

final productByIdProvider = FutureProvider.family<Product, int>((ref, id) async {
  return ref.read(wooClientProvider).fetchProductById(id);
});

final productVariationsProvider =
    FutureProvider.family<List<ProductVariation>, int>((ref, productId) async {
  return ref.read(wooClientProvider).fetchVariations(productId);
});

final categoryProductsProvider =
    FutureProvider.family<List<Product>, int?>((ref, categoryId) async {
  return ref.read(wooClientProvider).fetchProducts(
        categoryId: categoryId,
        page: 1,
        perPage: 20,
      );
});

final trendingNowProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(wooClientProvider).fetchProducts(
        page: 1,
        perPage: 20,
        orderBy: 'popularity',
      );
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(wooClientProvider).fetchProducts(
        page: 1,
        perPage: 20,
        orderBy: 'date',
        order: 'desc',
      );
});

final topSellingProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.read(wooClientProvider).fetchProducts(
        page: 1,
        perPage: 60,
      );
  products.sort((a, b) => b.totalSales.compareTo(a.totalSales));
  return products.take(20).toList();
});

final topCategoriesByCountProvider = Provider<List<ProductCategory>>((ref) {
  final roots = ref.watch(rootCategoriesProvider);
  final list = [...roots];
  list.sort((a, b) => b.count.compareTo(a.count));
  return list.take(8).toList();
});

final becauseViewedProvider = FutureProvider<List<Product>>((ref) async {
  final context = ref.watch(recentViewContextProvider);
  final viewedIds = context.productIds;
  if (viewedIds.isEmpty) return const <Product>[];

  final client = ref.read(wooClientProvider);
  final viewedSet = viewedIds.toSet();

  var relatedIds = {...context.relatedIds}..removeAll(viewedSet);
  var categoryIds = {...context.categoryIds};

  // Fill gaps when context was loaded from disk with ids only.
  if (relatedIds.isEmpty || categoryIds.isEmpty) {
    for (final id in viewedIds.take(3)) {
      try {
        final p = await client.fetchProductById(id);
        relatedIds.addAll(p.relatedIds.where((rid) => !viewedSet.contains(rid)));
        categoryIds.addAll(p.categoryIds);
      } catch (_) {}
    }
    relatedIds.removeAll(viewedSet);
  }

  if (relatedIds.isNotEmpty) {
    final related = <Product>[];
    for (final id in relatedIds.take(12)) {
      try {
        related.add(await client.fetchProductById(id));
      } catch (_) {}
    }
    final result =
        related.where((p) => !viewedSet.contains(p.id)).take(10).toList();
    if (result.isNotEmpty) return result;
  }

  if (categoryIds.isNotEmpty) {
    final similar = <Product>[];
    for (final catId in categoryIds.take(4)) {
      try {
        final batch = await client.fetchProducts(
          categoryId: catId,
          page: 1,
          perPage: 12,
        );
        similar.addAll(batch.where((p) => !viewedSet.contains(p.id)));
      } catch (_) {}
      if (similar.length >= 10) break;
    }
    if (similar.isNotEmpty) return similar.take(10).toList();
  }

  // Last resort so the section still appears after viewing products.
  try {
    final trending = await ref.read(trendingNowProvider.future);
    return trending.where((p) => !viewedSet.contains(p.id)).take(10).toList();
  } catch (_) {
    return const <Product>[];
  }
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(
    Product product, {
    int? variationId,
    Map<String, String> selectedAttributes = const {},
    double? unitPrice,
    int? maxStockQuantity,
  }) {
    final idx = state.indexWhere(
      (e) =>
          e.product.id == product.id &&
          (e.variationId ?? 0) == (variationId ?? 0),
    );
    if (idx == -1) {
      state = [
        ...state,
        CartItem(
          product: product,
          quantity: 1,
          variationId: variationId,
          selectedAttributes: selectedAttributes,
          unitPrice: unitPrice,
          maxStockQuantity: maxStockQuantity,
        ),
      ];
      return;
    }
    increment(product.id, variationId: variationId);
  }

  void increment(int productId, {int? variationId}) {
    state = [
      for (final item in state)
        if (item.product.id == productId &&
            (item.variationId ?? 0) == (variationId ?? 0))
          item.copyWith(
            quantity: _nextAllowedQuantity(item),
          )
        else
          item,
    ];
  }

  int _nextAllowedQuantity(CartItem item) {
    final stock = item.maxStockQuantity ?? item.product.stockQuantity;
    if (stock == null || stock <= 0) return item.quantity + 1;
    if (item.quantity >= stock) return stock;
    return item.quantity + 1;
  }

  void decrement(int productId, {int? variationId}) {
    final current = state.firstWhere(
      (e) =>
          e.product.id == productId &&
          (e.variationId ?? 0) == (variationId ?? 0),
    );
    if (current.quantity <= 1) {
      remove(productId, variationId: variationId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId &&
            (item.variationId ?? 0) == (variationId ?? 0))
          item.copyWith(quantity: item.quantity - 1)
        else
          item,
    ];
  }

  void remove(int productId, {int? variationId}) {
    state = state
        .where(
          (e) =>
              !(e.product.id == productId &&
                  (e.variationId ?? 0) == (variationId ?? 0)),
        )
        .toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.lineTotal);
});

final shippingProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0) return 0;
  if (subtotal > 100) return 0;
  return 8.99;
});

final taxProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal * 0.07;
});

final appliedCouponProvider = StateProvider<String>((ref) => '');
final couponDiscountProvider = StateProvider<double>((ref) => 0);

final cartGrandTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final shipping = ref.watch(shippingProvider);
  final tax = ref.watch(taxProvider);
  final discount = ref.watch(couponDiscountProvider);
  return (subtotal + shipping + tax - discount).clamp(0, double.infinity);
});

class CheckoutPayload {
  CheckoutPayload({
    required this.customer,
    required this.paymentMethod,
    required this.paymentTitle,
    required this.couponCode,
  });

  final CustomerInfo customer;
  final String paymentMethod;
  final String paymentTitle;
  final String couponCode;
}

final checkoutProvider =
    FutureProvider.family<int, CheckoutPayload>((ref, payload) async {
  final items = ref.read(cartProvider);
  if (items.isEmpty) throw Exception('Cart is empty');
  final lineItems = items
      .map((e) => {
            'product_id': e.product.id,
            'quantity': e.quantity,
            if (e.variationId != null) 'variation_id': e.variationId,
          })
      .toList();

  return ref.read(wooClientProvider).createOrder(
        customer: payload.customer,
        lineItems: lineItems,
        paymentMethod: payload.paymentMethod,
        paymentMethodTitle: payload.paymentTitle,
        couponLines: payload.couponCode.isEmpty
            ? []
            : [
                {'code': payload.couponCode}
              ],
      );
});
