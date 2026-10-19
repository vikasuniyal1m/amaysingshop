import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const Duration addedToBagSnackBarDuration = Duration(seconds: 5);

void showAddedToBagSnackBar({
  required String message,
  VoidCallback? onCheckout,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.brandActive,
      behavior: SnackBarBehavior.floating,
      duration: addedToBagSnackBarDuration,
      // SnackBars with an action stay visible until dismissed unless persist is false.
      persist: false,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: onCheckout == null
          ? null
          : SnackBarAction(
              label: 'Checkout',
              textColor: AppTheme.textLight,
              onPressed: onCheckout,
            ),
    ),
  );
}

void dismissAddedToBagSnackBar() {
  rootScaffoldMessengerKey.currentState?.clearSnackBars();
}
