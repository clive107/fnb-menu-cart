import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/utils/app/app_routes.dart';

/// Opens the cart. Shows the number of items in a badge; only this button
/// rebuilds when the count changes.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    /* Section - BlocSelector for CartCubit */
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.totalQuantity,
      builder: (context, totalQuantity) => IconButton(
        icon: Badge(
          isLabelVisible: totalQuantity > 0,
          label: Text('$totalQuantity'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
        tooltip: switch (totalQuantity) {
          0 => 'Cart',
          1 => 'Cart, 1 item',
          _ => 'Cart, $totalQuantity items',
        },
      ),
    );
  }
}
