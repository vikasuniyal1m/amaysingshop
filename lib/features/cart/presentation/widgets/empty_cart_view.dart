import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';

/// Figma empty cart: back button, bag icon, title, Explore Categories CTA.
class EmptyCartView extends StatelessWidget {
  const EmptyCartView({
    super.key,
    required this.onBack,
    required this.onExploreCategories,
  });

  final VoidCallback onBack;
  final VoidCallback onExploreCategories;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.emptyCartParcel,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 27),
                  const Text(
                    'Your Cart is Empty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 27),
                  Material(
                    color: AppTheme.brandActive,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      onTap: onExploreCategories,
                      borderRadius: BorderRadius.circular(100),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Text(
                          'Explore Categories',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 27,
            top: 12,
            child: _BackButton(onTap: onBack),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.chevron_left,
            size: 24,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
