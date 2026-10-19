class VariationAttribute {
  VariationAttribute({
    required this.name,
    required this.option,
  });

  final String name;
  final String option;

  factory VariationAttribute.fromJson(Map<String, dynamic> json) {
    return VariationAttribute(
      name: json['name'] as String? ?? '',
      option: json['option'] as String? ?? '',
    );
  }
}

class ProductVariation {
  ProductVariation({
    required this.id,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.inStock,
    required this.stockStatus,
    required this.stockQuantity,
    required this.attributes,
  });

  final int id;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool inStock;
  final String stockStatus;
  final int? stockQuantity;
  final List<VariationAttribute> attributes;

  /// WooCommerce can report `in_stock: false` while `stock_status` is instock
  /// or `stock_quantity` is set (especially with string quantities in JSON).
  bool get isSellable {
    final status = stockStatus.toLowerCase();
    if (status == 'instock' || status == 'onbackorder') return true;
    if (inStock) return true;
    final qty = stockQuantity;
    if (qty != null && qty > 0) return true;
    return false;
  }

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] as List<dynamic>? ?? [])
        .map((e) => VariationAttribute.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawQty = json['stock_quantity'];
    final qty = rawQty is int
        ? rawQty
        : int.tryParse(rawQty?.toString() ?? '');
    final status = (json['stock_status'] as String? ?? '').toLowerCase();
    final inStock = json['in_stock'] as bool? ??
        (status == 'instock' || status == 'onbackorder');
    return ProductVariation(
      id: json['id'] as int? ?? 0,
      price: json['price'] as String? ?? '0',
      regularPrice: json['regular_price'] as String? ?? '',
      salePrice: json['sale_price'] as String? ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      inStock: inStock,
      stockStatus: json['stock_status'] as String? ?? '',
      stockQuantity: qty,
      attributes: attrs,
    );
  }
}
