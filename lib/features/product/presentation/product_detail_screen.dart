import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../../core/models/product_price_info.dart';
import '../../../core/models/product_variation.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/product_content_sanitizer.dart';
import '../../../core/widgets/added_to_bag_snackbar.dart';
import '../../../core/widgets/favourite_button.dart';
import 'widgets/product_detail_image_carousel.dart';
import 'widgets/product_detail_reviews_section.dart';
import 'widgets/product_detail_selector_row.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, String> _selectedAttrs = {};
  int _quantity = 1;
  int? _trackedProductId;
  int? _defaultsInitializedForProductId;

  static const _horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final variationAsync = ref.watch(productVariationsProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brandActive),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (product) {
          _trackProductView(product);

          final variations = variationAsync.valueOrNull ?? const <ProductVariation>[];
          _maybeInitDefaultSelections(
            product,
            variations,
            variationsLoading: variationAsync.isLoading,
          );

          final selectedVariation =
              _findMatchingVariation(variations, _selectedAttrs);
          final priceInfo = selectedVariation != null
              ? ProductPriceInfo.fromVariation(selectedVariation)
              : ProductPriceInfo.fromProduct(product);

          final maxQty = _maxQuantity(product, selectedVariation);
          if (_quantity > maxQty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _quantity = maxQty.clamp(1, maxQty));
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              _CircleIconButton(
                                icon: Icons.chevron_left,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              Material(
                                color: AppTheme.surfaceCard,
                                shape: const CircleBorder(),
                                child: FavouriteButton(
                                  product: product,
                                  size: 40,
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ProductDetailImageCarousel(images: product.images),
                      const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _horizontalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildPriceDisplay(priceInfo),
                                const SizedBox(height: 20),
                                ..._buildSelectorRows(
                                  product,
                                  variations,
                                  variationAsync,
                                ),
                                const SizedBox(height: 12),
                                ProductDetailQuantityRow(
                                  quantity: _quantity,
                                  canDecrement: _quantity > 1,
                                  canIncrement: _quantity < maxQty,
                                  onDecrement: () => setState(
                                    () => _quantity =
                                        (_quantity - 1).clamp(1, maxQty),
                                  ),
                                  onIncrement: () => setState(
                                    () => _quantity =
                                        (_quantity + 1).clamp(1, maxQty),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildDescription(product),
                                const SizedBox(height: 24),
                                const Text(
                                  'Shipping & Returns',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Free standard shipping and free 60-day returns',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                ProductDetailReviewsSection(
                                  averageRating: product.averageRating,
                                  ratingCount: product.ratingCount,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(
                product,
                priceInfo,
                selectedVariation,
                variations,
              ),
            ],
          );
        },
      ),
    );
  }

  void _trackProductView(Product product) {
    if (_trackedProductId != product.id) {
      _trackedProductId = product.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _trackedProductId != product.id) return;
        ref.read(lastViewedProductIdProvider.notifier).state = product.id;
        ref.read(recentViewContextProvider.notifier).trackProduct(
              productId: product.id,
              categoryIds: product.categoryIds,
              relatedIds: product.relatedIds,
            );
        ref.read(recentSearchesProvider.notifier).add(product.name);
      });
    }
  }

  Widget _buildPriceDisplay(ProductPriceInfo priceInfo) {
    if (priceInfo.isVariableFromOptions) {
      return const Text(
        'Select options for price',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.brandActive,
        ),
      );
    }

    if (priceInfo.isOnSale && priceInfo.regularLabel != null) {
      return Row(
        children: [
          Text(
            priceInfo.currentLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandActive,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            priceInfo.regularLabel!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    return Text(
      priceInfo.currentLabel,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.brandActive,
      ),
    );
  }

  List<Widget> _buildSelectorRows(
    Product product,
    List<ProductVariation> variations,
    AsyncValue<List<ProductVariation>> variationAsync,
  ) {
    if (!product.hasVariants) return const [];

    return variationAsync.when(
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(color: AppTheme.brandActive),
        ),
      ],
      error: (e, _) => [
        Text('Could not load options: $e'),
      ],
      data: (_) {
        final variableAttrs = product.attributes
            .where((a) => a.variation && a.options.isNotEmpty)
            .toList();

        return variableAttrs.map((attr) {
          final selected = _selectedAttrs[attr.name] ?? attr.options.first;
          final isColor = _isColorAttr(attr.name);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductDetailSelectorRow(
              label: _selectorLabel(attr.name),
              value: selected,
              leading: isColor
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _colorFromName(selected),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.textPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                    )
                  : null,
              onTap: () => _openOptionPicker(
                attrName: attr.name,
                options: attr.options,
                variations: variations,
                isColor: isColor,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Future<void> _openOptionPicker({
    required String attrName,
    required List<String> options,
    required List<ProductVariation> variations,
    required bool isColor,
  }) async {
    final current = _selectedAttrs[attrName];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxListHeight = MediaQuery.sizeOf(ctx).height * 0.55;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select ${_selectorLabel(attrName)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxListHeight),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        final inStock =
                            _isOptionInStock(attrName, opt, variations);
                        final selected = current == opt;
                        return Material(
                          color: selected
                              ? AppTheme.brandActive.withValues(alpha: 0.12)
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: inStock
                                ? () {
                                    setState(() {
                                      _selectedAttrs[attrName] = opt;
                                      _quantity = 1;
                                    });
                                    Navigator.pop(ctx);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  if (isColor) ...[
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _colorFromName(opt),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.textPrimary
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Text(
                                      inStock
                                          ? opt
                                          : '$opt — Out of stock',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: inStock
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppTheme.brandActive,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildBottomBar(
    Product product,
    ProductPriceInfo priceInfo,
    ProductVariation? selectedVariation,
    List<ProductVariation> variations,
  ) {
    final canOrder = product.hasVariants
        ? (selectedVariation?.isSellable ?? false)
        : product.isSellableSimple;

    final displayPrice = priceInfo.isVariableFromOptions
        ? '—'
        : priceInfo.currentLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(_horizontalPadding, 12, _horizontalPadding, 12),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: canOrder ? AppTheme.brandActive : AppTheme.navInactive,
          borderRadius: BorderRadius.circular(100),
          child: InkWell(
            onTap: canOrder
                ? () => _addToCart(product, selectedVariation)
                : null,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Row(
                children: [
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Add to Bag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart(Product product, ProductVariation? selectedVariation) {
    final priceInfo = selectedVariation != null
        ? ProductPriceInfo.fromVariation(selectedVariation)
        : ProductPriceInfo.fromProduct(product);
    final unitPrice = double.tryParse(priceInfo.currentPrice) ?? 0;

    for (var i = 0; i < _quantity; i++) {
      ref.read(cartProvider.notifier).add(
            product,
            variationId: selectedVariation?.id,
            unitPrice: unitPrice,
            selectedAttributes: {
              for (final e in _selectedAttrs.entries) e.key: e.value,
            },
            maxStockQuantity: selectedVariation?.stockQuantity,
          );
    }

    showAddedToBagSnackBar(
      message: _quantity == 1
          ? 'Added to bag'
          : 'Added $_quantity items to bag',
      onCheckout: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ref.read(selectedBottomTabProvider.notifier).state = 2;
      },
    );
  }

  void _maybeInitDefaultSelections(
    Product product,
    List<ProductVariation> variations, {
    required bool variationsLoading,
  }) {
    if (_defaultsInitializedForProductId == product.id) return;
    if (!product.hasVariants) {
      _defaultsInitializedForProductId = product.id;
      return;
    }
    if (variations.isEmpty && variationsLoading) return;

    _defaultsInitializedForProductId = product.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var changed = false;
      for (final attr in product.attributes) {
        if (!attr.variation || attr.options.isEmpty) continue;
        if (_selectedAttrs.containsKey(attr.name)) continue;

        final firstInStock = attr.options.firstWhere(
          (o) => _isOptionInStock(attr.name, o, variations),
          orElse: () => attr.options.first,
        );
        _selectedAttrs[attr.name] = firstInStock;
        changed = true;
      }
      if (changed) setState(() {});
    });
  }

  int _maxQuantity(Product product, ProductVariation? variation) {
    if (variation?.stockQuantity != null && variation!.stockQuantity! > 0) {
      return variation.stockQuantity!;
    }
    if (!product.hasVariants &&
        product.stockQuantity != null &&
        product.stockQuantity! > 0) {
      return product.stockQuantity!;
    }
    return 99;
  }

  String _descriptionHtml(Product product) {
    final raw = product.description.isNotEmpty
        ? product.description
        : product.shortDescription;
    return ProductContentSanitizer.sanitizeHtml(raw);
  }

  Widget _buildDescription(Product product) {
    final html = _descriptionHtml(product);
    if (html.isEmpty) {
      return const Text(
        'No description available.',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
      );
    }

    return _buildHtmlWidget(html);
  }

  Widget _buildHtmlWidget(String html) {
    return HtmlWidget(
      html,
      textStyle: const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: AppTheme.textMuted,
      ),
      customStylesBuilder: (element) {
        final tag = element.localName ?? '';
        if (tag == 'h1' || tag == 'h2' || tag == 'h3') {
          return {
            'font-size': '15px',
            'font-weight': 'bold',
            'color': '#272727',
            'margin': '4px 0',
          };
        }
        if (tag == 'p') {
          return {'margin': '4px 0', 'padding': '0'};
        }
        if (tag == 'ul' || tag == 'ol') {
          return {'margin': '4px 0', 'padding-left': '16px'};
        }
        if (tag == 'strong' || tag == 'b') {
          return {'font-weight': 'bold', 'color': '#272727'};
        }
        return {'margin': '0', 'padding': '0'};
      },
    );
  }

  String _selectorLabel(String attrName) {
    final n = _normalizeAttrName(attrName);
    if (n.contains('size')) return 'Size';
    if (n.contains('color') || n.contains('colour')) return 'Color';
    if (attrName.isEmpty) return 'Option';
    return attrName;
  }

  bool _isColorAttr(String name) {
    final n = _normalizeAttrName(name);
    return n.contains('color') || n.contains('colour');
  }

  Color _colorFromName(String name) {
    final key = name.trim().toLowerCase();
    const map = {
      'black': Color(0xFF1A1A1A),
      'white': Color(0xFFF5F5F5),
      'red': Color(0xFFC62828),
      'blue': Color(0xFF1565C0),
      'green': Color(0xFF7A9E7E),
      'olive': Color(0xFF808000),
      'sage': Color(0xFF9CAF88),
      'grey': Color(0xFF9E9E9E),
      'gray': Color(0xFF9E9E9E),
      'brown': Color(0xFF795548),
      'beige': Color(0xFFD7CCC8),
      'navy': Color(0xFF1A237E),
      'pink': Color(0xFFF48FB1),
      'yellow': Color(0xFFFFEB3B),
      'orange': Color(0xFFFF9800),
      'purple': Color(0xFF7B1FA2),
    };
    for (final entry in map.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return AppTheme.surfaceGrey;
  }

  bool _isOptionInStock(
    String attrName,
    String option,
    List<ProductVariation> variations,
  ) {
    final normalizedAttr = _normalizeAttrName(attrName);
    final normalizedOpt = option.trim().toLowerCase();

    final matching = variations.where((v) {
      var hasThisOption = false;
      for (final a in v.attributes) {
        if (_normalizeAttrName(a.name) == normalizedAttr &&
            a.option.trim().toLowerCase() == normalizedOpt) {
          hasThisOption = true;
        }
      }
      if (!hasThisOption) return false;

      for (final entry in _selectedAttrs.entries) {
        if (_normalizeAttrName(entry.key) == normalizedAttr) continue;
        final picked = entry.value.trim().toLowerCase();
        var found = false;
        for (final a in v.attributes) {
          if (_normalizeAttrName(a.name) ==
                  _normalizeAttrName(entry.key) &&
              a.option.trim().toLowerCase() == picked) {
            found = true;
            break;
          }
        }
        if (!found) return false;
      }
      return true;
    });

    if (matching.isEmpty) return true;
    return matching.any((v) => v.isSellable);
  }

  ProductVariation? _findMatchingVariation(
    List<ProductVariation> variations,
    Map<String, String> selected,
  ) {
    if (variations.isEmpty) return null;
    for (final variation in variations) {
      var match = true;
      for (final attr in variation.attributes) {
        final name = _normalizeAttrName(attr.name);
        final option = attr.option.trim().toLowerCase();
        final picked =
            _findSelectedValueForName(selected, name).trim().toLowerCase();
        if (option.isEmpty) continue;
        if (option != picked) {
          match = false;
          break;
        }
      }
      if (match) return variation;
    }
    return null;
  }

  String _normalizeAttrName(String name) {
    final lowered = name.trim().toLowerCase();
    if (lowered.startsWith('pa_')) {
      return lowered.substring(3).replaceAll('-', ' ');
    }
    return lowered.replaceAll('-', ' ');
  }

  String _findSelectedValueForName(
    Map<String, String> selected,
    String normalizedName,
  ) {
    for (final entry in selected.entries) {
      if (_normalizeAttrName(entry.key) == normalizedName) {
        return entry.value;
      }
    }
    return '';
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 24, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
