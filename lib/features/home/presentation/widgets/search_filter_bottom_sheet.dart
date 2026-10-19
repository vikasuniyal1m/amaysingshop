import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchFilterBottomSheet extends StatelessWidget {
  const SearchFilterBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.onClear,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClear;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    VoidCallback? onClear,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(
        title: title,
        onClear: onClear,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.close, size: 24, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class SearchFilterOptionTile extends StatelessWidget {
  const SearchFilterOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandActive : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.textLight : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppTheme.textLight, size: 24),
          ],
        ),
      ),
    );
  }
}

class SearchPriceFilterFields extends StatefulWidget {
  const SearchPriceFilterFields({
    super.key,
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  final double initialMin;
  final double initialMax;
  final void Function(double min, double max) onApply;

  @override
  State<SearchPriceFilterFields> createState() => _SearchPriceFilterFieldsState();
}

class _SearchPriceFilterFieldsState extends State<SearchPriceFilterFields> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initialMin > 0 ? widget.initialMin.toStringAsFixed(0) : '',
    );
    _maxController = TextEditingController(
      text: widget.initialMax < 500 ? widget.initialMax.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minController.text.trim()) ?? 0;
    final max = double.tryParse(_maxController.text.trim()) ?? 500;
    widget.onApply(min, max.clamp(0, 10000));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _priceField(controller: _minController, hint: 'Min'),
        const SizedBox(height: 16),
        _priceField(controller: _maxController, hint: 'Max'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandActive,
              foregroundColor: AppTheme.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _priceField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(100),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.textPrimary.withValues(alpha: 0.45),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
