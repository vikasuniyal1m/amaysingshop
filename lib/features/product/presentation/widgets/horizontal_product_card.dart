import 'package:flutter/material.dart';

import '../../../../core/models/product.dart';
import '../../../../core/models/product_price_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/favourite_button.dart';
import 'product_price_row.dart';

class HorizontalProductCard extends StatelessWidget {
  const HorizontalProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  static const double cardWidth = 159;
  static const double imageHeight = 180;

  @override
  Widget build(BuildContext context) {
    final priceInfo = ProductPriceInfo.fromProduct(product);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
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
                width: cardWidth,
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.images.isNotEmpty)
                      Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        width: cardWidth,
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
              Padding(
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
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}
