import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../product/presentation/product_detail_screen.dart';
import '../../product/presentation/widgets/horizontal_product_card.dart';
import 'category_products_screen.dart';
import 'search_screen.dart';
import 'see_all_products_screen.dart';
import 'widgets/home_branding_bar.dart';
import 'widgets/home_section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingNowProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final viewContext = ref.watch(recentViewContextProvider);
    final suggestedAsync =
        viewContext.productIds.isEmpty ? null : ref.watch(becauseViewedProvider);
    final topCategories = ref.watch(rootCategoriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandActive,
          onRefresh: () => _onRefresh(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeBrandingBar(),
                _buildSearchBar(context),
                const SizedBox(height: 24),
                _buildCategoriesSection(context, ref, topCategories),
                const SizedBox(height: 24),
                _buildProductRowSection(
                  context: context,
                  ref: ref,
                  title: 'Top Selling',
                  productsAsync: trendingAsync,
                  listType: ProductListType.trending,
                ),
                const SizedBox(height: 24),
                _buildProductRowSection(
                  context: context,
                  ref: ref,
                  title: 'New In',
                  titleColor: AppTheme.brandActive,
                  productsAsync: newArrivalsAsync,
                  listType: ProductListType.newArrivals,
                ),
                if (suggestedAsync != null) ...[
                  const SizedBox(height: 24),
                  _buildSuggestedSection(context, ref, suggestedAsync),
                ],
                const SizedBox(height: 24),
                _buildCategoryWiseProductSections(
                  context,
                  ref,
                  topCategories,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(trendingNowProvider);
    ref.invalidate(newArrivalsProvider);
    ref.invalidate(becauseViewedProvider);
    for (final cat in homeDisplayCategories(ref.read(rootCategoriesProvider))) {
      ref.invalidate(categoryProductsProvider(cat.id));
    }
    await ref.read(homeProductsProvider.notifier).refresh();
  }

  Widget _buildCategoryWiseProductSections(
    BuildContext context,
    WidgetRef ref,
    List<ProductCategory> categories,
  ) {
    final displayCategories = homeDisplayCategories(categories);
    if (displayCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < displayCategories.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _HomeCategoryProductRow(category: displayCategories[i]),
        ],
      ],
    );
  }

  /// Hidden until the user has opened at least one product detail.
  Widget _buildSuggestedSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> suggestedAsync,
  ) {
    return suggestedAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandActive,
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildProductRowSection(
          context: context,
          ref: ref,
          title: 'Suggested For You',
          productsAsync: AsyncValue.data(items),
          listType: ProductListType.suggested,
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 19),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: AppTheme.textPrimary),
              SizedBox(width: 12),
              Text(
                'Search',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    WidgetRef ref,
    List<ProductCategory> categories,
  ) {
    final displayCategories = homeDisplayCategories(categories);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: 'Categories',
            onSeeAll: () {
              ref.read(selectedCategoryProvider.notifier).state = null;
              ref.read(selectedBottomTabProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 92,
            child: displayCategories.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final cat = displayCategories[index];
                      return _CircleCategoryItem(
                        name: cat.name,
                        imageUrl: cat.imageUrl,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state =
                              cat.id;
                          ref.read(selectedBottomTabProvider.notifier).state =
                              1;
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRowSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required AsyncValue<List<Product>> productsAsync,
    ProductListType? listType,
    VoidCallback? onSeeAll,
    Color titleColor = AppTheme.textPrimary,
  }) {
    return buildHomeProductRowSection(
      context: context,
      title: title,
      productsAsync: productsAsync,
      listType: listType,
      onSeeAll: onSeeAll,
      titleColor: titleColor,
    );
  }
}

Widget buildHomeProductRowSection({
  required BuildContext context,
  required String title,
  required AsyncValue<List<Product>> productsAsync,
  ProductListType? listType,
  VoidCallback? onSeeAll,
  Color titleColor = AppTheme.textPrimary,
}) {
  assert(listType != null || onSeeAll != null);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: HomeScreen._horizontalPadding),
        child: HomeSectionHeader(
          title: title,
          titleColor: titleColor,
          onSeeAll: onSeeAll ??
              () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SeeAllProductsScreen(
                        title: title,
                        listType: listType!,
                      ),
                    ),
                  ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: HorizontalProductCard.imageHeight + 72,
        child: productsAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeScreen._horizontalPadding,
              ),
              child: Text('Failed to load: $e', textAlign: TextAlign.center),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No products'));
            }
            final list = items.take(10).toList();
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeScreen._horizontalPadding,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = list[index];
                return HorizontalProductCard(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(productId: product.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

List<ProductCategory> homeDisplayCategories(List<ProductCategory> categories) {
  return categories
      .where((c) =>
          c.name.trim().toLowerCase() != 'all' &&
          c.slug.trim().toLowerCase() != 'all')
      .toList();
}

class _HomeCategoryProductRow extends ConsumerWidget {
  const _HomeCategoryProductRow({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsProvider(category.id));

    return productsAsync.when(
      skipLoadingOnRefresh: false,
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return buildHomeProductRowSection(
          context: context,
          title: category.name,
          productsAsync: AsyncValue.data(items),
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                categoryId: category.id,
                categoryName: category.name,
                productCount: category.count,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleCategoryItem extends StatelessWidget {
  const _CircleCategoryItem({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: AppTheme.surfaceCard,
                      child: Icon(
                        Icons.category_outlined,
                        color: AppTheme.textPrimary.withValues(alpha: 0.4),
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
