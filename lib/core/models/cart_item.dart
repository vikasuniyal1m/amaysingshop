import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    this.variationId,
    this.selectedAttributes = const {},
    this.unitPrice,
    this.maxStockQuantity,
  });

  final Product product;
  final int quantity;
  final int? variationId;
  final Map<String, String> selectedAttributes;
  final double? unitPrice;
  /// When set (e.g. variation line), caps quantity in cart.
  final int? maxStockQuantity;

  double get lineTotal => (unitPrice ?? (double.tryParse(product.price) ?? 0)) * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    int? variationId,
    Map<String, String>? selectedAttributes,
    double? unitPrice,
    int? maxStockQuantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variationId: variationId ?? this.variationId,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
      unitPrice: unitPrice ?? this.unitPrice,
      maxStockQuantity: maxStockQuantity ?? this.maxStockQuantity,
    );
  }
}
