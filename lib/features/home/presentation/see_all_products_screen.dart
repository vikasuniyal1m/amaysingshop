import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/product.dart';
import '../../../core/providers/app_providers.dart';
import 'widgets/category_product_list_scaffold.dart';

enum ProductListType { trending, newArrivals, popular, suggested }

class SeeAllProductsScreen extends ConsumerStatefulWidget {
  const SeeAllProductsScreen({
    super.key,
    required this.title,
    required this.listType,
  });

  final String title;
  final ProductListType listType;

  @override
  ConsumerState<SeeAllProductsScreen> createState() =>
      _SeeAllProductsScreenState();
}

class _SeeAllProductsScreenState extends ConsumerState<SeeAllProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final client = ref.read(wooClientProvider);

    switch (widget.listType) {
      case ProductListType.trending:
        return client.fetchProducts(
          page: 1,
          perPage: 40,
          orderBy: 'popularity',
        );
      case ProductListType.newArrivals:
        return client.fetchProducts(
          page: 1,
          perPage: 40,
          orderBy: 'date',
          order: 'desc',
        );
      case ProductListType.popular:
        return client.fetchProducts(
          page: 1,
          perPage: 40,
          orderBy: 'rating',
        );
      case ProductListType.suggested:
        return ref.read(becauseViewedProvider.future);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _fetchProducts();
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
      final products = await _fetchProducts();
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
      title: categoryTitleWithCount(widget.title, _products.length),
      products: _products,
      isLoading: _isLoading,
      isRefreshing: _isRefreshing,
      error: _error,
      onRefresh: _onRefresh,
    );
  }
}
