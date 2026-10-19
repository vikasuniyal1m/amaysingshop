import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/snackbar_route_observer.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/added_to_bag_snackbar.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/home/presentation/categories_screen.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: AmaySingApp()));
}

class AmaySingApp extends ConsumerWidget {
  const AmaySingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Amay Sing Shop',
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorObservers: [dismissSnackBarsNavigatorObserver],
      home: const HomeShell(),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: selected ? AppTheme.brandActive : AppTheme.navInactive,
          ),
        ),
      ),
    );
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(selectedBottomTabProvider, (previous, next) {
      if (previous != null && previous != next) {
        dismissAddedToBagSnackBar();
      }
    });

    final rawIndex = ref.watch(selectedBottomTabProvider);
    final index = rawIndex.clamp(0, _tabs.length - 1);
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: ColoredBox(
        color: AppTheme.primary,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selected: index == 0,
                  onTap: () => ref.read(selectedBottomTabProvider.notifier).state = 0,
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  selected: index == 1,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    ref.read(selectedBottomTabProvider.notifier).state = 1;
                  },
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  selected: index == 2,
                  onTap: () => ref.read(selectedBottomTabProvider.notifier).state = 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
