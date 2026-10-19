import 'product.dart';

/// Cached product snapshot for the favourites list (offline-friendly).
class FavouriteEntry {
  const FavouriteEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final String? imageUrl;

  factory FavouriteEntry.fromProduct(Product product) {
    return FavouriteEntry(
      id: product.id,
      name: product.name,
      price: product.price,
      regularPrice: product.regularPrice,
      salePrice: product.salePrice,
      onSale: product.onSale,
      imageUrl: product.images.isNotEmpty ? product.images.first : null,
    );
  }

  factory FavouriteEntry.fromJson(Map<String, dynamic> json) {
    return FavouriteEntry(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '0',
      regularPrice: json['regular_price'] as String? ?? '',
      salePrice: json['sale_price'] as String? ?? '',
      onSale: json['on_sale'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'regular_price': regularPrice,
        'sale_price': salePrice,
        'on_sale': onSale,
        'image_url': imageUrl,
      };

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      slug: '',
      price: price,
      regularPrice: regularPrice,
      salePrice: salePrice,
      onSale: onSale,
      description: '',
      shortDescription: '',
      inStock: true,
      stockStatus: 'instock',
      purchasable: true,
      stockQuantity: null,
      type: 'simple',
      images: imageUrl != null && imageUrl!.isNotEmpty ? [imageUrl!] : const [],
      attributes: const [],
      totalSales: 0,
      relatedIds: const [],
      categoryIds: const [],
      averageRating: 0,
      ratingCount: 0,
    );
  }
}
