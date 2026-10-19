import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';

/// Figma empty search results: illustration + message + CTA.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.onExploreCategories,
  });

  final VoidCallback onExploreCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.emptySearch,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            "Sorry, we couldn't find any matching result for your Search.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onExploreCategories,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.brandActive,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Explore Categories',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
