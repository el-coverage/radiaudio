import 'package:flutter/material.dart';

void showQuickSnackMessage({
  required BuildContext context,
  required String text,
  int milliseconds = 300,
  VoidCallback? onClosed,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: Duration(milliseconds: milliseconds),
    ),
  );
  if (onClosed != null) {
    controller.closed.then((_) => onClosed());
  }
}
