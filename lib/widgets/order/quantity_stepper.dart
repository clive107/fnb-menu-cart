import 'package:flutter/material.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';

/// "− 2 +" control for a cart quantity.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  // False disables both buttons, e.g. while an order is in flight.
  final bool isEnabled;
  // False disables only "+", e.g. once the cart holds all the stock.
  final bool canIncrement;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.isEnabled = true,
    this.canIncrement = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: isEnabled ? onDecrement : null,
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
          onPressed: isEnabled && canIncrement ? onIncrement : null,
          tooltip: 'Add one',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
