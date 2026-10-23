part of 'cart_cubit.dart';

class CartState extends Equatable {
  /// Cart items keyed by menu item ID, in the order they were first added.
  final Map<int, CartItem> cartItemsById;

  const CartState({this.cartItemsById = const {}});

  /* Section - Derived values */
  // Worked out from cartItemsById rather than stored, so they can't drift
  // out of sync with it.
  List<CartItem> get cartItemList => cartItemsById.values.toList();

  bool get isEmpty => cartItemsById.isEmpty;

  int get totalQuantity => cartItemsById.values.fold(
    0,
    (int sum, CartItem cartItem) => sum + cartItem.quantity,
  );

  int get totalInCents => cartItemsById.values.fold(
    0,
    (int sum, CartItem cartItem) => sum + cartItem.subtotalInCents,
  );

  int quantityOf(int menuItemId) => cartItemsById[menuItemId]?.quantity ?? 0;

  /// Quantity per menu item ID, the shape an order request needs.
  Map<int, int> get quantityByItemId => {
    for (final CartItem cartItem in cartItemsById.values)
      cartItem.menuItem.id: cartItem.quantity,
  };

  @override
  List<Object?> get props => [cartItemsById];
}
