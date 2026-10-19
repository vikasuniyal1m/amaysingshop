class ProductCategory {
  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.parentId,
    required this.count,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String slug;
  final int parentId;
  final int count;
  final String? imageUrl;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      parentId: json['parent'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      imageUrl:
          (json['image'] as Map<String, dynamic>?)?['src'] as String?,
    );
  }
}
