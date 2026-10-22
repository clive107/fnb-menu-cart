import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';

/// "− 2 +" control for a cart quantity.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: onDecrement,
          tooltip: 'Remove one',
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: onIncrement,
          tooltip: 'Add one',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
