import '../api/woocommerce_client.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/recent_view_context.dart';

/// Fast product search: one primary API call + optional parallel category lookups.
class ProductSearchEngine {
  ProductSearchEngine(this._client);

  final WooCommerceClient _client;

  final Map<String, List<Product>> _cache = {};
  static const _cacheTtl = Duration(minutes: 3);
  static const _maxCategoryFetches = 2;
  static const _apiPerPage = 30;
  static const _categoryPerPage = 12;

  Future<List<Product>> search({
    required String query,
    required List<ProductCategory> categories,
    String? orderBy,
    String? order,
    RecentViewContext viewContext = const RecentViewContext(),
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final cacheKey = '$normalized|$orderBy|$order';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final catById = {for (final c in categories) c.id: c};
    final matchingCategoryIds = _topMatchingCategoryIds(categories, normalized);

    final futures = <Future<List<Product>>>[
      _client.fetchProducts(
        search: query,
        perPage: _apiPerPage,
        orderBy: orderBy,
        order: order,
      ),
    ];

    for (final id in matchingCategoryIds) {
      futures.add(
        _client.fetchProducts(
          categoryId: id,
          perPage: _categoryPerPage,
          orderBy: orderBy,
          order: order,
        ),
      );
    }

    final batches = await Future.wait(futures);

    final byId = <int, Product>{};
    for (final list in batches) {
      for (final product in list) {
        byId[product.id] = product;
      }
    }

    final tokens = _tokens(normalized);
    final matchingSet = matchingCategoryIds.toSet();
    final filtered = byId.values
        .where(
          (p) => _productMatches(
            p,
            normalized,
            tokens,
            matchingSet,
            catById,
          ),
        )
        .toList();

    final result = _applyOrderBy(
      filtered,
      orderBy,
      order,
      normalized,
      tokens,
      catById,
      viewContext,
    );
    _cache[cacheKey] = result;
    Future.delayed(_cacheTtl, () => _cache.remove(cacheKey));
    return result;
  }

  static List<String> _tokens(String query) {
    return query
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.length > 1)
        .toList();
  }

  /// Best matching category IDs only (no tree expansion) — limits extra API calls.
  static List<int> _topMatchingCategoryIds(
    List<ProductCategory> all,
    String query,
  ) {
    if (all.isEmpty) return const [];

    final tokens = _tokens(query);
    final scored = <(int id, int score)>[];

    for (final cat in all) {
      final name = cat.name.toLowerCase();
      final slug = cat.slug.toLowerCase().replaceAll('-', ' ');
      var score = 0;

      if (name == query || slug == query.replaceAll(' ', '-')) {
        score = 100;
      } else if (name.startsWith(query) || slug.startsWith(query)) {
        score = 80;
      } else if (name.contains(query) || slug.contains(query)) {
        score = 60;
      } else if (tokens.isNotEmpty &&
          tokens.every((t) => name.contains(t) || slug.contains(t))) {
        score = 50;
      }

      if (score > 0) {
        scored.add((cat.id, score));
      }
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(_maxCategoryFetches).map((e) => e.$1).toList();
  }

  static bool _productMatches(
    Product product,
    String query,
    List<String> tokens,
    Set<int> matchingCategoryIds,
    Map<int, ProductCategory> catById,
  ) {
    final title = product.name.toLowerCase();
    final slug = product.slug.toLowerCase().replaceAll('-', ' ');

    if (title.contains(query) || slug.contains(query)) return true;

    if (tokens.isNotEmpty && tokens.every((t) => title.contains(t))) {
      return true;
    }

    if (product.categoryIds.any(matchingCategoryIds.contains)) return true;

    for (final id in product.categoryIds) {
      final cat = catById[id];
      if (cat == null) continue;
      final name = cat.name.toLowerCase();
      if (name.contains(query)) return true;
      if (tokens.isNotEmpty && tokens.every(name.contains)) return true;
    }

    return false;
  }

  static int _relevanceScore(
    Product product,
    String query,
    List<String> tokens,
    Map<int, ProductCategory> catById,
  ) {
    var score = 0;
    final title = product.name.toLowerCase();

    if (title == query) {
      score += 120;
    } else if (title.startsWith(query)) {
      score += 90;
    } else if (title.contains(query)) {
      score += 70;
    }

    if (tokens.isNotEmpty && tokens.every(title.contains)) {
      score += 50;
    }

    for (final id in product.categoryIds) {
      final cat = catById[id];
      if (cat == null) continue;
      final name = cat.name.toLowerCase();
      if (name == query) {
        score += 45;
      } else if (name.contains(query)) {
        score += 30;
      } else if (tokens.isNotEmpty && tokens.every(name.contains)) {
        score += 20;
      }
    }

    score += product.totalSales.clamp(0, 15);
    return score;
  }

  static List<Product> _applyOrderBy(
    List<Product> products,
    String? orderBy,
    String? order,
    String query,
    List<String> tokens,
    Map<int, ProductCategory> catById,
    RecentViewContext viewContext,
  ) {
    final list = List<Product>.from(products);
    switch (orderBy) {
      case 'price':
        list.sort((a, b) => a.numericPrice.compareTo(b.numericPrice));
        break;
      case 'price-desc':
        list.sort((a, b) => b.numericPrice.compareTo(a.numericPrice));
        break;
      case 'date':
        break;
      case 'popularity':
      default:
        list.sort((a, b) {
          final recommended = _recommendedScore(b, viewContext)
              .compareTo(_recommendedScore(a, viewContext));
          if (recommended != 0) return recommended;
          return _relevanceScore(b, query, tokens, catById)
              .compareTo(_relevanceScore(a, query, tokens, catById));
        });
        break;
    }
    return list;
  }

  /// Boost products related to what the user has viewed (like home "Suggested For You").
  static int _recommendedScore(Product product, RecentViewContext context) {
    if (context.productIds.contains(product.id)) return 300;
    if (context.relatedIds.contains(product.id)) return 220;
    if (product.categoryIds.any(context.categoryIds.contains)) return 140;
    return product.totalSales.clamp(0, 30);
  }
}
