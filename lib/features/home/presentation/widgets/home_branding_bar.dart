import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/providers/favourites_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../favourites/presentation/favourites_screen.dart';

class HomeBrandingBar extends ConsumerWidget {
  const HomeBrandingBar({super.key});

  static const _horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouriteCount = ref.watch(favouriteCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_horizontalPadding, 8, _horizontalPadding, 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_logo.png',
              height: 44,
              width: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppTheme.brandActive,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AmaySing Shop',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandActive,
                height: 1.2,
                letterSpacing: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavouritesScreen()),
            ),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.heart,
                    width: 22,
                    height: 22,
                  ),
                  if (favouriteCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.brandActive,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: Text(
                          favouriteCount > 99 ? '99+' : '$favouriteCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
