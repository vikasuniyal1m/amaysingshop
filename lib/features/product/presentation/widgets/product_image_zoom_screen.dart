import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Full-screen image viewer with pinch-to-zoom and pan.
class ProductImageZoomScreen extends StatefulWidget {
  const ProductImageZoomScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<ProductImageZoomScreen> createState() => _ProductImageZoomScreenState();
}

class _ProductImageZoomScreenState extends State<ProductImageZoomScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.images.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: widget.images.length == 1
          ? _ZoomableNetworkImage(
              url: widget.images.first,
              onZoomChanged: (zoomed) => setState(() => _isZoomed = zoomed),
            )
          : PageView.builder(
              controller: _pageController,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _isZoomed = false;
              }),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return _ZoomableNetworkImage(
                  key: ValueKey(widget.images[index]),
                  url: widget.images[index],
                  onZoomChanged: (zoomed) => setState(() => _isZoomed = zoomed),
                );
              },
            ),
    );
  }
}

class _ZoomableNetworkImage extends StatefulWidget {
  const _ZoomableNetworkImage({
    super.key,
    required this.url,
    required this.onZoomChanged,
  });

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableNetworkImage> createState() => _ZoomableNetworkImageState();
}

class _ZoomableNetworkImageState extends State<_ZoomableNetworkImage> {
  final TransformationController _transformController =
      TransformationController();

  static const _zoomedScaleThreshold = 1.01;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed =
        _transformController.value.getMaxScaleOnAxis() > _zoomedScaleThreshold;
    widget.onZoomChanged(zoomed);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    widget.onZoomChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        final zoomed =
            _transformController.value.getMaxScaleOnAxis() > _zoomedScaleThreshold;
        if (zoomed) {
          _resetZoom();
        } else {
          final size = MediaQuery.sizeOf(context);
          final dx = size.width / 2;
          final dy = size.height / 2;
          _transformController.value = Matrix4.identity()
            ..translateByDouble(dx, dy, 0, 1)
            ..scaleByDouble(2.5, 2.5, 1, 1)
            ..translateByDouble(-dx, -dy, 0, 1);
          widget.onZoomChanged(true);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1,
        maxScale: 4,
        panEnabled: true,
        scaleEnabled: true,
        child: Center(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.textLight),
              );
            },
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: AppTheme.navInactive,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

void openProductImageZoom(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
}) {
  if (images.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ProductImageZoomScreen(
        images: images,
        initialIndex: initialIndex,
      ),
    ),
  );
}
