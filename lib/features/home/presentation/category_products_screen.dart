import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../../core/providers/app_providers.dart';
import 'widgets/category_product_list_scaffold.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.productCount,
  });

  final int? categoryId;
  final String categoryName;
  final int? productCount;

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  int get _displayCount {
    final fromCategory = widget.productCount ?? 0;
    if (fromCategory > 0) return fromCategory;
    return _products.length;
  }

  String get _title =>
      categoryTitleWithCount(widget.categoryName, _displayCount);

  Future<void> _loadProducts() async {
    try {
      final client = ref.read(wooClientProvider);
      final products = await client.fetchAllProducts(
        categoryId: widget.categoryId,
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      final client = ref.read(wooClientProvider);
      final products = await client.fetchAllProducts(
        categoryId: widget.categoryId,
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CategoryProductListScaffold(
      title: _title,
      products: _products,
      isLoading: _isLoading,
      isRefreshing: _isRefreshing,
      error: _error,
      onRefresh: _onRefresh,
    );
  }
}
