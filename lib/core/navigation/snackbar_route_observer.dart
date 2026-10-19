import 'package:flutter/material.dart';

import '../widgets/added_to_bag_snackbar.dart';

/// Dismisses floating "added to bag" snackbars when the user navigates away.
class DismissSnackBarsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss();
  }

  void _dismiss() {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
  }
}

final dismissSnackBarsNavigatorObserver =
    DismissSnackBarsNavigatorObserver();
