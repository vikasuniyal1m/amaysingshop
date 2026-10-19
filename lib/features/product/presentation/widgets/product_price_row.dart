import 'package:flutter/material.dart';

import '../../../../core/models/product_price_info.dart';
import '../../../../core/theme/app_theme.dart';

class ProductPriceRow extends StatelessWidget {
  const ProductPriceRow({
    super.key,
    required this.priceInfo,
    this.saleFontSize = 14,
    this.regularFontSize = 12,
    this.saleFontWeight = FontWeight.w700,
    this.saleColor = AppTheme.brandActive,
    this.regularColor = AppTheme.textMuted,
  });

  final ProductPriceInfo priceInfo;
  final double saleFontSize;
  final double regularFontSize;
  final FontWeight saleFontWeight;
  final Color saleColor;
  final Color regularColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          priceInfo.currentLabel,
          style: TextStyle(
            fontSize: saleFontSize,
            fontWeight: saleFontWeight,
            color: saleColor,
            height: 1.2,
          ),
        ),
        if (priceInfo.isOnSale && priceInfo.regularLabel != null) ...[
          SizedBox(width: saleFontSize >= 14 ? 8 : 6),
          _CenterStrikethroughPrice(
            text: priceInfo.regularLabel!,
            fontSize: regularFontSize,
            color: regularColor,
          ),
        ],
      ],
    );
  }
}

/// Draws a line through the vertical center of the price text (not the line box).
class _CenterStrikethroughPrice extends StatelessWidget {
  const _CenterStrikethroughPrice({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CenterStrikePainter(
        color: color,
        strokeWidth: 1,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.0,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}

class _CenterStrikePainter extends CustomPainter {
  _CenterStrikePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _CenterStrikePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
