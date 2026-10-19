import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class FilterScreen extends ConsumerWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FilterView(
      orderBy: ref.watch(orderByProvider),
      inStockOnly: ref.watch(inStockOnlyProvider),
    );
  }
}

class _FilterView extends ConsumerStatefulWidget {
  const _FilterView({
    required this.orderBy,
    required this.inStockOnly,
  });

  final String orderBy;
  final bool inStockOnly;

  @override
  ConsumerState<_FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends ConsumerState<_FilterView> {
  late String _orderBy;
  late bool _inStockOnly;
  RangeValues _priceRange = const RangeValues(0, 500);

  @override
  void initState() {
    super.initState();
    _orderBy = widget.orderBy;
    _inStockOnly = widget.inStockOnly;
  }

  static const _sortOptions = [
    ('popularity', 'Popular'),
    ('date', 'Latest'),
    ('price', 'Low to High'),
    ('price-desc', 'High to Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        Text(
                          '\$${_priceRange.start.toInt()}-\$${_priceRange.end.toInt()}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF6D2D2D),
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFF6D2D2D).withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 2,
                        ),
                        trackHeight: 3,
                      ),
                      child: RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 500,
                        onChanged: (values) => setState(() => _priceRange = values),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sort By',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _sortOptions.map((option) {
                        final isSelected = _orderBy == option.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _orderBy = option.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF6D2D2D) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6D2D2D) : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              option.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _inStockOnly = !_inStockOnly),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _inStockOnly ? const Color(0xFF6D2D2D) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _inStockOnly ? const Color(0xFF6D2D2D) : Colors.grey.shade400,
                              ),
                            ),
                            child: _inStockOnly
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'In stock only',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(orderByProvider.notifier).state = _orderBy;
                      ref.read(inStockOnlyProvider.notifier).state = _inStockOnly;
                      ref.read(minPriceProvider.notifier).state = _priceRange.start;
                      ref.read(maxPriceProvider.notifier).state = _priceRange.end;
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D2D2D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text(
                      'Apply Filter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
