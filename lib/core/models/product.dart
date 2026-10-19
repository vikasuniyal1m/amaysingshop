import '../utils/product_content_sanitizer.dart';

class Product {
  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.description,
    required this.shortDescription,
    required this.inStock,
    required this.stockStatus,
    required this.purchasable,
    required this.stockQuantity,
    required this.type,
    required this.images,
    required this.attributes,
    required this.totalSales,
    required this.relatedIds,
    required this.categoryIds,
    required this.averageRating,
    required this.ratingCount,
  });

  final int id;
  final String name;
  final String slug;
  final String price;
  final String regularPrice;
  final String salePrice;
  /// WooCommerce `on_sale` — product has an active sale price.
  final bool onSale;
  final String description;
  final String shortDescription;
  final bool inStock;
  /// WooCommerce: `instock` | `outofstock` | `onbackorder`
  final String stockStatus;
  final bool purchasable;
  final int? stockQuantity;
  final String type;
  final List<String> images;
  final List<ProductAttribute> attributes;
  final int totalSales;
  final List<int> relatedIds;
  final List<int> categoryIds;
  final double averageRating;
  final int ratingCount;

  bool get hasVariants => type == 'variable';
  double get numericPrice => double.tryParse(price) ?? 0;

  /// List/grid label: variable parents often have misleading `in_stock` vs variations.
  bool get showsAsAvailableInCatalog {
    if (!purchasable) return false;
    final s = stockStatus.toLowerCase();
    if (hasVariants) {
      return s != 'outofstock';
    }
    return s == 'instock' ||
        s == 'onbackorder' ||
        inStock ||
        (stockQuantity != null && stockQuantity! > 0);
  }

  /// Simple (non-variable) product: can add to cart without choosing a variation.
  bool get isSellableSimple {
    if (hasVariants) return false;
    if (!purchasable) return false;
    final s = stockStatus.toLowerCase();
    if (s == 'instock' || s == 'onbackorder') return true;
    if (inStock) return true;
    final qty = stockQuantity;
    if (qty != null && qty > 0) return true;
    return false;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['src'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final rawQty = json['stock_quantity'];
    final qty = rawQty is int
        ? rawQty
        : int.tryParse(rawQty?.toString() ?? '');
    final status = (json['stock_status'] as String? ?? '').toLowerCase();
    final inStock = json['in_stock'] as bool? ??
        (status == 'instock' || status == 'onbackorder');
    return Product(
      id: json['id'] as int? ?? 0,
      name: ProductContentSanitizer.sanitizePlainText(
        json['name'] as String? ?? '',
      ),
      slug: json['slug'] as String? ?? '',
      price: json['price'] as String? ?? '0',
      regularPrice: json['regular_price'] as String? ?? '',
      salePrice: json['sale_price'] as String? ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      description: ProductContentSanitizer.sanitizeHtml(
        json['description'] as String? ?? '',
      ),
      shortDescription: ProductContentSanitizer.sanitizeHtml(
        json['short_description'] as String? ?? '',
      ),
      inStock: inStock,
      stockStatus: json['stock_status'] as String? ?? '',
      purchasable: json['purchasable'] as bool? ?? true,
      stockQuantity: qty,
      type: json['type'] as String? ?? 'simple',
      images: images,
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((e) => ProductAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSales: json['total_sales'] as int? ?? 0,
      relatedIds: (json['related_ids'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      categoryIds: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['id'] as int? ?? 0)
          .where((id) => id > 0)
          .toList(),
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }
}

class ProductAttribute {
  ProductAttribute({
    required this.id,
    required this.name,
    required this.variation,
    required this.options,
  });

  final int id;
  final String name;
  final bool variation;
  final List<String> options;

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      variation: json['variation'] as bool? ?? false,
      options:
          (json['options'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
    );
  }
}
