import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';
import '../models/product.dart';
import '../providers/favourites_provider.dart';

/// Heart toggle for adding/removing a product from favourites.
class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({
    super.key,
    required this.product,
    this.size = 24,
    this.iconSize = 16,
    this.padding = EdgeInsets.zero,
  });

  final Product product;
  final double size;
  final double iconSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavourite = ref.watch(isProductFavouriteProvider(product.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(favouritesProvider.notifier).toggle(product),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: padding,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SvgPicture.asset(
                isFavourite ? AppAssets.heartFill : AppAssets.heart,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
