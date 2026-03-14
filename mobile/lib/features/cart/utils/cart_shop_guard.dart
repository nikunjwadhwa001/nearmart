import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialogs.dart';

Future<bool> showReplaceCartDialog(
  BuildContext context, {
  required String currentShopName,
  required String newShopName,
}) async {
  final shouldReplace = await showAppConfirmDialog(
    context,
    title: 'Replace cart items?',
    message:
        'Your cart has items from $currentShopName. To add items from '
        '$newShopName, current cart will be cleared.',
    confirmText: 'Replace',
  );

  return shouldReplace;
}
