import 'product.dart';
import 'product_variation.dart';

/// Normalized sale/regular pricing from WooCommerce API fields.
class ProductPriceInfo {
  const ProductPriceInfo({
    required this.currentPrice,
    this.regularPrice,
    required this.isOnSale,
    this.isVariableFromOptions = false,
  });

  final String currentPrice;
  final String? regularPrice;
  final bool isOnSale;
  final bool isVariableFromOptions;

  static double? _amount(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  static bool _isDiscount({
    required bool? onSaleFlag,
    required String price,
    required String regularPrice,
    required String salePrice,
  }) {
    if (onSaleFlag == true) return true;

    final regular = _amount(regularPrice);
    final sale = _amount(salePrice);
    if (regular != null && sale != null && sale > 0 && sale < regular) {
      return true;
    }

    final current = _amount(price);
    if (regular != null && current != null && current > 0 && current < regular) {
      return true;
    }

    return false;
  }

  static String _current({
    required bool isOnSale,
    required String price,
    required String salePrice,
    required String regularPrice,
  }) {
    if (isOnSale) {
      final sale = _amount(salePrice);
      if (sale != null && sale > 0) return salePrice;
      if (price.isNotEmpty) return price;
    }
    if (price.isNotEmpty) return price;
    return regularPrice;
  }

  factory ProductPriceInfo.fromProduct(Product product) {
    if (product.hasVariants && product.numericPrice == 0) {
      return const ProductPriceInfo(
        currentPrice: '',
        isOnSale: false,
        isVariableFromOptions: true,
      );
    }

    final onSale = _isDiscount(
      onSaleFlag: product.onSale,
      price: product.price,
      regularPrice: product.regularPrice,
      salePrice: product.salePrice,
    );
    final current = _current(
      isOnSale: onSale,
      price: product.price,
      salePrice: product.salePrice,
      regularPrice: product.regularPrice,
    );
    final regular = product.regularPrice.isNotEmpty ? product.regularPrice : null;

    return ProductPriceInfo(
      currentPrice: current,
      regularPrice: onSale ? regular : null,
      isOnSale: onSale,
    );
  }

  factory ProductPriceInfo.fromVariation(ProductVariation variation) {
    final onSale = _isDiscount(
      onSaleFlag: variation.onSale,
      price: variation.price,
      regularPrice: variation.regularPrice,
      salePrice: variation.salePrice,
    );
    final current = _current(
      isOnSale: onSale,
      price: variation.price,
      salePrice: variation.salePrice,
      regularPrice: variation.regularPrice,
    );

    return ProductPriceInfo(
      currentPrice: current,
      regularPrice: onSale && variation.regularPrice.isNotEmpty
          ? variation.regularPrice
          : null,
      isOnSale: onSale,
    );
  }

  String get currentLabel =>
      isVariableFromOptions ? 'From options' : '\$$currentPrice';

  String? get regularLabel =>
      regularPrice != null && regularPrice!.isNotEmpty ? '\$$regularPrice' : null;
}
