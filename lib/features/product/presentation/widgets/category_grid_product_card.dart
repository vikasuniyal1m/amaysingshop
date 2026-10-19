import 'package:flutter/material.dart';

import '../../../../core/models/product.dart';
import '../../../../core/models/product_price_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/favourite_button.dart';
import 'product_price_row.dart';

/// Product card for 2-column grids (Figma: fixed cell height, 220/161 image ratio).
class CategoryGridProductCard extends StatelessWidget {
  const CategoryGridProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  static const double _figmaImageHeightRatio = 220 / 161;

  /// Fixed height for title + price block so every card matches in the grid.
  static const double textBlockHeight = 74;

  @override
  Widget build(BuildContext context) {
    final priceInfo = ProductPriceInfo.fromProduct(product);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final imageHeight = (height - textBlockHeight).clamp(0.0, height);

        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: height,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: width,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (product.images.isNotEmpty)
                          Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            width: width,
                            height: imageHeight,
                          )
                        else
                          const ColoredBox(
                            color: Color(0xFFD9D9D9),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 8,
                          child: FavouriteButton(product: product),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: textBlockHeight,
                    width: width,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          ProductPriceRow(
                            priceInfo: priceInfo,
                            saleFontSize: 12,
                            regularFontSize: 12,
                            saleColor: AppTheme.textPrimary,
                            saleFontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Grid `childAspectRatio` for a given cell width (uniform card height).
  static double aspectRatioForCellWidth(double cellWidth) {
    final imageHeight = cellWidth * _figmaImageHeightRatio;
    return cellWidth / (imageHeight + textBlockHeight);
  }
}
