import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'product_image_zoom_screen.dart';

class ProductDetailImageCarousel extends StatefulWidget {
  const ProductDetailImageCarousel({
    super.key,
    required this.images,
    this.height = 320,
  });

  final List<String> images;
  final double height;

  @override
  State<ProductDetailImageCarousel> createState() =>
      _ProductDetailImageCarouselState();
}

class _ProductDetailImageCarouselState extends State<ProductDetailImageCarousel> {
  static const _horizontalPadding = 16.0;
  static const _itemGap = 10.0;
  /// ~2 images visible at once with a peek of the next (Figma).
  static const _multiImageViewportFraction = 0.48;

  PageController? _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _pageController = PageController(
        viewportFraction: _multiImageViewportFraction,
      );
    }
  }

  @override
  void didUpdateWidget(ProductDetailImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadMulti = oldWidget.images.length > 1;
    final hasMulti = widget.images.length > 1;
    if (hadMulti != hasMulti) {
      _pageController?.dispose();
      _pageController = hasMulti
          ? PageController(viewportFraction: _multiImageViewportFraction)
          : null;
      _index = 0;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppTheme.navInactive,
            ),
          ),
        ),
      );
    }

    if (widget.images.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: _ImageCard(
          url: widget.images.first,
          height: widget.height,
          onTap: () => openProductImageZoom(
            context,
            images: widget.images,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? _horizontalPadding : _itemGap / 2,
                  right: _itemGap / 2,
                ),
                child: SizedBox(
                  height: widget.height,
                  child: _ImageCard(
                    url: widget.images[i],
                    height: widget.height,
                    onTap: () => openProductImageZoom(
                      context,
                      images: widget.images,
                      initialIndex: i,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (i) => Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _index
                    ? AppTheme.brandActive
                    : AppTheme.navInactive,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.url,
    required this.height,
    this.onTap,
  });

  final String url;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: AppTheme.surfaceCard,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
              alignment: Alignment.center,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.brandActive,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppTheme.navInactive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
