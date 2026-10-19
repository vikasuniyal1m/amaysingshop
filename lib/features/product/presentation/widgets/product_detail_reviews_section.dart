import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProductDetailReviewsSection extends StatelessWidget {
  const ProductDetailReviewsSection({
    super.key,
    required this.averageRating,
    required this.ratingCount,
  });

  final double averageRating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    if (ratingCount <= 0 && averageRating <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              averageRating > 0
                  ? averageRating.toStringAsFixed(1)
                  : '—',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Ratings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$ratingCount ${ratingCount == 1 ? 'Review' : 'Reviews'}',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        _StarRow(rating: averageRating),
        if (ratingCount > 0) ...[
          const SizedBox(height: 20),
          Text(
            'Customer reviews are collected on our store. '
            'Check back soon for more detailed feedback.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = rating >= i + 1 - 0.25;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 22,
          color: filled ? AppTheme.brandActive : AppTheme.surfaceGrey,
        );
      }),
    );
  }
}
