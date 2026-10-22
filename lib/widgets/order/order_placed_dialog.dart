import 'package:flutter/material.dart';

/// Confirms a successful order. Completes when the user dismisses it.
Future<void> showOrderPlacedDialog({
  required BuildContext context,
  int? orderId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
      content: Text(
        orderId != null
            ? "Thanks! We've received your order #$orderId."
            : "Thanks! We've received your order.",
      ),
      icon: const Icon(Icons.check_circle_outline),
      title: const Text('Order placed'),
    ),
  );
}
