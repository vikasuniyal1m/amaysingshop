/// Tracks recently viewed products for "Recommended" ranking (search + home).
class RecentViewContext {
  const RecentViewContext({
    this.productIds = const [],
    this.categoryIds = const {},
    this.relatedIds = const {},
  });

  final List<int> productIds;
  final Set<int> categoryIds;
  final Set<int> relatedIds;

  bool get isEmpty =>
      productIds.isEmpty && categoryIds.isEmpty && relatedIds.isEmpty;
}
