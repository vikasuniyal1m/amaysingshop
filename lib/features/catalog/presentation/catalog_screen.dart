import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../product/presentation/product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _orderBy = 'popularity';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppStateScope.of(context);
      state.loadCategories();
      state.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return RefreshIndicator(
      onRefresh: () => state.loadProducts(
        categoryId: _selectedCategoryId,
        search: _searchController.text,
        orderBy: _orderBy,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => state.loadProducts(
                  categoryId: _selectedCategoryId,
                  search: _searchController.text,
                  orderBy: _orderBy,
                ),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedCategoryId == null,
                onSelected: (_) {
                  setState(() => _selectedCategoryId = null);
                  state.loadProducts(search: _searchController.text, orderBy: _orderBy);
                },
              ),
              ...state.categories.map((category) {
                return ChoiceChip(
                  label: Text(category.name),
                  selected: _selectedCategoryId == category.id,
                  onSelected: (_) {
                    setState(() => _selectedCategoryId = category.id);
                    state.loadProducts(
                      categoryId: category.id,
                      search: _searchController.text,
                      orderBy: _orderBy,
                    );
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _orderBy,
            items: const [
              DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
              DropdownMenuItem(value: 'rating', child: Text('Rating')),
              DropdownMenuItem(value: 'date', child: Text('Latest')),
              DropdownMenuItem(value: 'price', child: Text('Price: Low to High')),
              DropdownMenuItem(value: 'price-desc', child: Text('Price: High to Low')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _orderBy = value);
              state.loadProducts(
                categoryId: _selectedCategoryId,
                search: _searchController.text,
                orderBy: value,
              );
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (state.isLoading) const Center(child: CircularProgressIndicator()),
          if (state.error != null)
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ...state.products.map((product) {
            return Card(
              child: ListTile(
                leading: product.images.isNotEmpty
                    ? Image.network(product.images.first, width: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(product.name),
                subtitle: Text('\$${product.price}'),
                trailing: Icon(product.inStock ? Icons.check_circle : Icons.cancel),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
