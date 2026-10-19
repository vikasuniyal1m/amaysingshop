import 'package:flutter/material.dart';

import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/presentation/product_detail_screen.dart';
import '../../../product/presentation/widgets/category_grid_product_card.dart';

/// Figma category listing: circular back, title with count, 2-column product grid.
class CategoryProductListScaffold extends StatelessWidget {
  const CategoryProductListScaffold({
    super.key,
    required this.title,
    required this.products,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.onRefresh,
    this.horizontalPadding = 24,
  });

  final String title;
  final List<Product> products;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Future<void> Function()? onRefresh;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: isLoading && products.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.brandActive),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    title: title,
                    horizontalPadding: horizontalPadding,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: _buildBody(context)),
                ],
              ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (onRefresh == null) {
      return _buildContent(context);
    }
    return RefreshIndicator(
      color: AppTheme.brandActive,
      onRefresh: onRefresh!,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isRefreshing)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.brandActive),
              ),
            ),
          )
        else if (error != null && products.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  'Failed to load: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else if (products.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No products found')),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              24,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: CategoryGridProductCard.aspectRatioForCellWidth(
                  (MediaQuery.sizeOf(context).width -
                          horizontalPadding * 2 -
                          20) /
                      2,
                ),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return CategoryGridProductCard(
                    product: product,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          productId: product.id,
                        ),
                      ),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.horizontalPadding,
    required this.onBack,
  });

  final String title;
  final double horizontalPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 24,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

String categoryTitleWithCount(String name, int count) {
  if (count > 0) return '$name ($count)';
  return name;
}
