import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/configs/themes/styles.dart';
import 'package:fnb_menu_cart/models/order/cart_item.dart';
import 'package:fnb_menu_cart/utils/data_types/price.dart';
import 'package:fnb_menu_cart/widgets/order/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      /* Section - BlocBuilder for CartCubit */
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const _EmptyCart();
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: Column(
                children: [
                  /* Section - Cart items */
                  Expanded(
                    child: _CartItemList(cartItemList: state.cartItemList),
                  ),
                  /* Section - Cart summary */
                  const _CartSummary(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartItemList extends StatelessWidget {
  final List<CartItem> cartItemList;

  const _CartItemList({required this.cartItemList});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: cartItemList.length,
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemBuilder: (context, index) => CartItemTile(
        key: ValueKey<int>(cartItemList[index].menuItem.id),
        cartItem: cartItemList[index],
      ),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
    );
  }
}

/// The total, pinned below the list.
class _CartSummary extends StatelessWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text('Total', style: theme.textTheme.titleMedium),
              const Spacer(),
              /* Section - BlocSelector for CartCubit */
              BlocSelector<CartCubit, CartState, int>(
                selector: (state) => state.totalInCents,
                builder: (context, totalInCents) => Text(
                  formatPrice(totalInCents),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 48.0,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Your cart is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Browse menu'),
            ),
          ],
        ),
      ),
    );
  }
}
