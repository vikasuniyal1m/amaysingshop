import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../product/presentation/product_detail_screen.dart';
import '../../product/presentation/widgets/category_grid_product_card.dart';
import 'widgets/search_empty_state.dart';
import 'widgets/search_filter_bottom_sheet.dart';
import 'widgets/search_filter_chip.dart';
import 'widgets/search_header_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _searchDebounce;

  static const _sortOptions = <(String id, String label)>[
    ('date', 'Newest'),
    ('price', 'Lowest - Highest Price'),
    ('price-desc', 'Highest - Lowest Price'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    Future.microtask(() {
      _resetSearchFilters();
      ref.read(catalogCategoriesProvider.future);
    });
  }

  void _resetSearchFilters() {
    if (!mounted) return;
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(orderByProvider.notifier).state = 'popularity';
    ref.read(searchOnSaleOnlyProvider.notifier).state = false;
    ref.read(searchGenderCategoryIdProvider.notifier).state = null;
    ref.read(minPriceProvider.notifier).state = 0;
    ref.read(maxPriceProvider.notifier).state = 500;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _applySearchQuery(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).add(trimmed);
    }
    ref.read(searchQueryProvider.notifier).state = trimmed;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = value.trim();
    });
  }

  void _clearSearch() {
    _controller.clear();
    _applySearchQuery('');
  }

  int _activeFilterCount() {
    var count = 0;
    if (ref.read(searchOnSaleOnlyProvider)) count++;
    final min = ref.read(minPriceProvider);
    final max = ref.read(maxPriceProvider);
    if (min > 0 || max < 500) count++;
    if (ref.read(searchGenderCategoryIdProvider) != null) count++;
    if (ref.read(orderByProvider) != 'popularity') count++;
    return count;
  }

  void _clearAllFilters() {
    ref.read(orderByProvider.notifier).state = 'popularity';
    ref.read(searchOnSaleOnlyProvider.notifier).state = false;
    ref.read(searchGenderCategoryIdProvider.notifier).state = null;
    ref.read(minPriceProvider.notifier).state = 0;
    ref.read(maxPriceProvider.notifier).state = 500;
  }

  void _goToCategories() {
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(selectedBottomTabProvider.notifier).state = 1;
    Navigator.of(context).pop();
  }

  bool get _isPriceFilterActive {
    final min = ref.watch(minPriceProvider);
    final max = ref.watch(maxPriceProvider);
    return min > 0 || max < 500;
  }

  String _genderChipLabel(List<ProductCategory> roots, int? categoryId) {
    if (categoryId == null) return 'Men';
    return roots.where((c) => c.id == categoryId).firstOrNull?.name ?? 'Men';
  }

  ProductCategory? _genderCategory(List<ProductCategory> roots, String name) {
    return roots
        .where((c) => c.name.trim().toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }

  List<ProductCategory> _genderOptions(List<ProductCategory> roots) {
    const preferred = ['men', 'women', 'kids'];
    final options = <ProductCategory>[];
    for (final key in preferred) {
      final cat = _genderCategory(roots, key);
      if (cat != null) options.add(cat);
    }
    if (options.isEmpty) return roots.take(3).toList();
    return options;
  }

  Future<void> _openSortSheet() async {
    final current = ref.read(orderByProvider);
    await SearchFilterBottomSheet.show(
      context: context,
      title: 'Sort by',
      onClear: () {
        ref.read(orderByProvider.notifier).state = 'popularity';
        Navigator.of(context).pop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _sortOptions.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            SearchFilterOptionTile(
              label: _sortOptions[i].$2,
              selected: current == _sortOptions[i].$1,
              onTap: () {
                ref.read(orderByProvider.notifier).state = _sortOptions[i].$1;
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGenderSheet(List<ProductCategory> roots) async {
    final options = _genderOptions(roots);
    final selectedId = ref.read(searchGenderCategoryIdProvider);
    await SearchFilterBottomSheet.show(
      context: context,
      title: 'Gender',
      onClear: () {
        ref.read(searchGenderCategoryIdProvider.notifier).state = null;
        Navigator.of(context).pop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            SearchFilterOptionTile(
              label: options[i].name,
              selected: selectedId == options[i].id,
              onTap: () {
                ref.read(searchGenderCategoryIdProvider.notifier).state =
                    options[i].id;
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPriceSheet() async {
    final min = ref.read(minPriceProvider);
    final max = ref.read(maxPriceProvider);
    await SearchFilterBottomSheet.show(
      context: context,
      title: 'Price',
      onClear: () {
        ref.read(minPriceProvider.notifier).state = 0;
        ref.read(maxPriceProvider.notifier).state = 500;
        Navigator.of(context).pop();
      },
      child: SearchPriceFilterFields(
        initialMin: min,
        initialMax: max,
        onApply: (newMin, newMax) {
          ref.read(minPriceProvider.notifier).state = newMin;
          ref.read(maxPriceProvider.notifier).state = newMax;
        },
      ),
    );
  }

  Widget _buildFilterChips({
    required int filterCount,
    required bool onSale,
    required bool priceActive,
    required bool sortActive,
    required bool genderActive,
    required String genderLabel,
    required List<ProductCategory> roots,
  }) {
    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SearchHeaderBar.horizontalPadding),
        children: [
          SearchFilterChip(
            label: filterCount > 0 ? '$filterCount' : '',
            selected: filterCount > 0,
            onTap: () {
              if (filterCount > 0) _clearAllFilters();
            },
            leading: Icon(
              Icons.tune,
              size: 16,
              color: filterCount > 0 ? AppTheme.textLight : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          SearchFilterChip(
            label: 'On Sale',
            selected: onSale,
            onTap: () =>
                ref.read(searchOnSaleOnlyProvider.notifier).state = !onSale,
          ),
          const SizedBox(width: 4),
          SearchFilterChip(
            label: 'Price',
            selected: priceActive,
            showChevron: true,
            onTap: _openPriceSheet,
          ),
          const SizedBox(width: 4),
          SearchFilterChip(
            label: 'Sort by',
            selected: sortActive,
            showChevron: true,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: 4),
          SearchFilterChip(
            label: genderLabel,
            selected: genderActive,
            showChevron: true,
            onTap: () => _openGenderSheet(roots),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(homeProductsProvider);
    final roots = ref.watch(rootCategoriesProvider);
    final onSale = ref.watch(searchOnSaleOnlyProvider);
    final genderId = ref.watch(searchGenderCategoryIdProvider);
    final orderBy = ref.watch(orderByProvider);
    final filterCount = _activeFilterCount();
    final hasQuery = query.isNotEmpty;
    final cellWidth =
        (MediaQuery.sizeOf(context).width - SearchHeaderBar.horizontalPadding * 2 - 20) /
            2;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchHeaderBar(
              controller: _controller,
              onChanged: _onSearchChanged,
              onSubmitted: _applySearchQuery,
              onClear: _clearSearch,
              onBack: () => Navigator.of(context).pop(),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 24),
              _buildFilterChips(
                filterCount: filterCount,
                onSale: onSale,
                priceActive: _isPriceFilterActive,
                sortActive: orderBy != 'popularity',
                genderActive: genderId != null,
                genderLabel: _genderChipLabel(roots, genderId),
                roots: roots,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 24),
                child: results.when(
                  data: (list) => Text(
                    '${list.length} Results Found',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  loading: () => const Text(
                    'Searching...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _buildBody(
                query: query,
                results: results,
                cellWidth: cellWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required String query,
    required AsyncValue<List<Product>> results,
    required double cellWidth,
  }) {
    if (query.isEmpty) {
      return _buildRecentSearchesPanel();
    }

    return results.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.brandActive),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Search failed: $e', textAlign: TextAlign.center),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return SearchEmptyState(onExploreCategories: _goToCategories);
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            SearchHeaderBar.horizontalPadding,
            0,
            SearchHeaderBar.horizontalPadding,
            24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: CategoryGridProductCard.aspectRatioForCellWidth(cellWidth),
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final product = list[index];
            return CategoryGridProductCard(
              product: product,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: product.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearchesPanel() {
    final recentSearches = ref.watch(recentSearchesProvider).take(5).toList();
    final viewedAsync = ref.watch(recentlyViewedProductsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SearchHeaderBar.horizontalPadding,
        24,
        SearchHeaderBar.horizontalPadding,
        24,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
            if (recentSearches.isNotEmpty)
              GestureDetector(
                onTap: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentSearches.isEmpty)
          Text(
            'Search or open a product to see history here.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary.withValues(alpha: 0.55),
              height: 1.6,
            ),
          )
        else
          ...recentSearches.map(_buildRecentSearchRow),
        const SizedBox(height: 24),
        viewedAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (products) {
            if (products.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Based on products you viewed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                ...products.take(5).map(_buildViewedProductRow),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSearchRow(String term) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          _controller.text = term;
          _applySearchQuery(term);
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            const Icon(Icons.history, size: 16, color: AppTheme.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                term,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(recentSearchesProvider.notifier).remove(term),
              child: const Icon(Icons.close, size: 16, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewedProductRow(Product product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        ),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: product.images.isNotEmpty
                    ? Image.network(product.images.first, fit: BoxFit.cover)
                    : ColoredBox(
                        color: AppTheme.surfaceCard,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 18,
                          color: AppTheme.textPrimary.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _controller.text = product.name;
                _applySearchQuery(product.name);
              },
              child: const Icon(Icons.search, size: 16, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
