import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/favourites_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../product/presentation/product_detail_screen.dart';
import '../../product/presentation/widgets/category_grid_product_card.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  static const _horizontalPadding = 24.0;
  static const _gridSpacing = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider).items;
    final count = favourites.length;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                16,
              ),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(
                      count > 0 ? 'My Favourites ($count)' : 'My Favourites',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: favourites.isEmpty
                  ? const _EmptyFavouritesView()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final innerWidth =
                            constraints.maxWidth - (_horizontalPadding * 2);
                        final cellWidth =
                            (innerWidth - _gridSpacing) / 2;
                        final aspectRatio =
                            CategoryGridProductCard.aspectRatioForCellWidth(
                          cellWidth,
                        );

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            _horizontalPadding,
                            0,
                            _horizontalPadding,
                            24,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: _gridSpacing,
                            crossAxisSpacing: _gridSpacing,
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: favourites.length,
                          itemBuilder: (context, index) {
                            final product = favourites[index].toProduct();
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _EmptyFavouritesView extends StatelessWidget {
  const _EmptyFavouritesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 56,
              color: AppTheme.textPrimary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favourites yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on a product to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
