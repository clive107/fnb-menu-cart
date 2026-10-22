import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/blocs/order/checkout/checkout_bloc.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/models/order/cart_item.dart';
import 'package:fnb_menu_cart/utils/data_types/price.dart';
import 'package:fnb_menu_cart/widgets/order/quantity_stepper.dart';

/// One line in the cart: name, prices and quantity controls.
class CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const CartItemTile({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartCubit cartCubit = context.read<CartCubit>();
    final int menuItemId = cartItem.menuItem.id;

    /* Section - BlocSelector for CheckoutBloc */
    // Locked while an order is in flight, so the cart cleared on success is
    // exactly what was ordered.
    return BlocSelector<CheckoutBloc, CheckoutState, bool>(
      selector: (state) => state.placeOrderStatus.isLoading,
      builder: (context, isPlacingOrder) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              /* Section - Name and remove */
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cartItem.menuItem.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: isPlacingOrder
                        ? null
                        : () => cartCubit.removeItem(menuItemId),
                    tooltip: 'Remove',
                  ),
                ],
              ),
              /* Section - Prices and quantity */
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatPrice(cartItem.subtotalInCents),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${formatPrice(cartItem.menuItem.priceInCents)} each',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  QuantityStepper(
                    isEnabled: !isPlacingOrder,
                    onDecrement: () => cartCubit.decrementItem(menuItemId),
                    onIncrement: () => cartCubit.incrementItem(menuItemId),
                    quantity: cartItem.quantity,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
