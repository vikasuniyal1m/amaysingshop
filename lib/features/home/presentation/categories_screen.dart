import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/category.dart';
import '../../../core/providers/app_providers.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final roots = ref.watch(rootCategoriesProvider);
    final filteredRoots = roots
        .where(
          (e) =>
              e.name.trim().toLowerCase() != 'all' &&
              e.slug.trim().toLowerCase() != 'all',
        )
        .toList();
    final sortedRoots = [...filteredRoots]..sort((a, b) {
      if (a.name.toLowerCase() == 'men') return -1;
      if (b.name.toLowerCase() == 'men') return 1;
      if (a.name.toLowerCase() == 'women') return -1;
      if (b.name.toLowerCase() == 'women') return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final selectedRoot = _resolveSelectedRoot(sortedRoots);
    final subCategories = selectedRoot == null
        ? const <ProductCategory>[]
        : ref.watch(subCategoriesProvider(selectedRoot.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load categories: $e')),
        data: (_) {
          if (sortedRoots.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          return SafeArea(
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  child: ListView.builder(
                    itemCount: sortedRoots.length,
                    itemBuilder: (context, index) {
                      final root = sortedRoots[index];
                      return _RootCategoryTile(
                        category: root,
                        selected: selectedRoot?.id == root.id,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = root.id,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: subCategories.isEmpty
                        ? Center(
                            child: FilledButton(
                              onPressed: () => _openProducts(context, selectedRoot),
                              child: const Text('View products'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth < 460 ? 2 : 3;
                              return GridView.builder(
                                itemCount: subCategories.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.76,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                ),
                                itemBuilder: (context, index) {
                                  final sub = subCategories[index];
                                  return _SubCategoryTile(
                                    category: sub,
                                    onTap: () => _openProducts(context, sub),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ProductCategory? _resolveSelectedRoot(List<ProductCategory> roots) {
    if (roots.isEmpty) return null;
    final selectedId = ref.watch(selectedCategoryProvider);
    if (selectedId == null) return roots.first;
    return roots.where((e) => e.id == selectedId).firstOrNull ?? roots.first;
  }

  void _openProducts(BuildContext context, ProductCategory? category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(
          categoryId: category?.id,
          categoryName: category?.name ?? 'All products',
          productCount: category?.count,
        ),
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.category,
    required this.onTap,
  });

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = category.imageUrl != null && category.imageUrl!.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFE5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? Image.network(
                          category.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFF9F3F1),
                          alignment: Alignment.center,
                          child: _CategoryPlaceholderArt(
                            label: category.name,
                            size: 54,
                            circular: false,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootCategoryTile extends StatelessWidget {
  const _RootCategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF9F3F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF6D2D2D) : const Color(0xFFEFE5E1),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6D2D2D).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unique selection marker: double rail + diamond.
            Container(
              width: 8,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: selected ? const Color(0xFF6D2D2D) : const Color(0xFFECE5E2),
              ),
              child: selected
                  ? Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 8,
                        height: 8,
                        transform: Matrix4.rotationZ(0.78),
                        decoration: const BoxDecoration(color: Colors.white),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF6D2D2D) : Colors.black87,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF6D2D2D),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryPlaceholderArt extends StatelessWidget {
  const _CategoryPlaceholderArt({
    required this.label,
    required this.size,
    this.circular = false,
  });

  final String label;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final palette = _pickPalette(label);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.$1, palette.$2],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.auto_awesome_motion_rounded,
              color: Colors.white.withValues(alpha: 0.92),
              size: size * 0.34,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 7, right: 7),
              child: Icon(Icons.auto_awesome, size: size * 0.18, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _pickPalette(String source) {
    final hash = source.toLowerCase().trim().hashCode.abs();
    const palettes = <(Color, Color)>[
      (Color(0xFF6D2D2D), Color(0xFFB67B5B)),
      (Color(0xFF7A6A5F), Color(0xFF9D8A7D)),
      (Color(0xFF8E5E47), Color(0xFFC5967E)),
      (Color(0xFF705447), Color(0xFF9B7B6B)),
    ];
    return palettes[hash % palettes.length];
  }
}
