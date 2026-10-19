import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchHeaderBar extends StatelessWidget {
  const SearchHeaderBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final bool autofocus;

  static const horizontalPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 0),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.chevron_left,
            onTap: onBack,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 19),
                  const Icon(Icons.search, size: 16, color: AppTheme.textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextField(
                          controller: controller,
                          autofocus: autofocus,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          cursorColor: AppTheme.textPrimary,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(
                              color: Color(0x99272727),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 19),
                        child: Icon(Icons.close, size: 16, color: AppTheme.textPrimary),
                      ),
                    ),
                  ] else
                    const SizedBox(width: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
