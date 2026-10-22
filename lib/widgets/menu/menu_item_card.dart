import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/blocs/order/checkout/checkout_bloc.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/enums/menu/menu_item_availability.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';
import 'package:fnb_menu_cart/utils/data_types/price.dart';
import 'package:fnb_menu_cart/widgets/menu/menu_item_thumbnail.dart';
import 'package:fnb_menu_cart/widgets/order/quantity_stepper.dart';

/// One menu item. The card itself doesn't depend on the cart; only the
/// [_CartControl] at the bottom rebuilds when this item's quantity changes.
class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;

  const MenuItemCard({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isOutOfStock = menuItem.availability.isOutOfStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* Section - Thumbnail */
            // Faded when out of stock, so the item reads as unavailable.
            Opacity(
              opacity: isOutOfStock ? 0.4 : 1.0,
              child: MenuItemThumbnail(
                size: AppSizes.menuItemThumbnail,
                url: menuItem.thumbnailUrl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* Section - Name and description */
                  Opacity(
                    opacity: isOutOfStock ? 0.6 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(menuItem.name, style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          menuItem.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  /* Section - Price, availability and cart control */
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatPrice(menuItem.priceInCents),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isOutOfStock
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                                decoration: isOutOfStock
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            _AvailabilityLabel(
                              availability: menuItem.availability,
                            ),
                          ],
                        ),
                      ),
                      _CartControl(menuItem: menuItem),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityLabel extends StatelessWidget {
  final MenuItemAvailability availability;

  const _AvailabilityLabel({required this.availability});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (String label, Color color) = switch (availability) {
      MenuItemAvailability.inStock => (
        'In stock',
        theme.colorScheme.onSurfaceVariant,
      ),
      MenuItemAvailability.lowStock => (
        'Low stock',
        theme.colorScheme.tertiary,
      ),
      MenuItemAvailability.outOfStock => (
        'Out of stock',
        theme.colorScheme.error,
      ),
    };

    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

/// "Add" button, or a quantity stepper once the item is in the cart.
class _CartControl extends StatelessWidget {
  final MenuItem menuItem;

  const _CartControl({required this.menuItem});

  @override
  Widget build(BuildContext context) {
    /* Section - BlocSelector for CheckoutBloc */
    // Locked while an order is in flight, so the cart cleared on success is
    // exactly what was ordered.
    return BlocSelector<CheckoutBloc, CheckoutState, bool>(
      selector: (state) => state.placeOrderStatus.isLoading,
      builder: (context, isPlacingOrder) =>
          /* Section - BlocSelector for CartCubit */
          // Selects only this item's quantity, so a change to another item
          // doesn't rebuild this control.
          BlocSelector<CartCubit, CartState, int>(
            selector: (state) => state.quantityOf(menuItem.id),
            builder: (context, quantity) {
              final CartCubit cartCubit = context.read<CartCubit>();
              // Fixed height: the Add button is taller than the stepper, so
              // without it the card would shrink when one replaces the other.
              return SizedBox(
                height: AppSizes.buttonHeight,
                child: Center(
                  child: quantity == 0
                      ? FilledButton.tonalIcon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          // Disabled for out-of-stock items, and while an
                          // order is in flight.
                          onPressed:
                              menuItem.availability.isOutOfStock ||
                                  isPlacingOrder
                              ? null
                              : () => cartCubit.addItem(menuItem),
                        )
                      : QuantityStepper(
                          isEnabled: !isPlacingOrder,
                          onDecrement: () =>
                              cartCubit.decrementItem(menuItem.id),
                          onIncrement: () => cartCubit.addItem(menuItem),
                          quantity: quantity,
                        ),
                ),
              );
            },
          ),
    );
  }
}
