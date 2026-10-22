import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/enums/menu/menu_item_availability.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';
import 'package:fnb_menu_cart/models/order/cart_item.dart';
import 'package:logger/logger.dart';

part 'cart_state.dart';

/// In-memory cart. Provided above MaterialApp, so it survives navigation,
/// rotation and theme changes.
class CartCubit extends Cubit<CartState> {
  static const String _kTag = '[CartCubit]';

  final Logger _logger;

  CartCubit({required Logger logger})
    : _logger = logger,
      super(const CartState());

  /// Adds one of [menuItem], or one more if it's already in the cart.
  /// Out-of-stock items are ignored.
  void addItem(MenuItem menuItem) {
    if (menuItem.availability.isOutOfStock) {
      _logger.w('$_kTag addItem: ${menuItem.id} is out of stock, ignoring');
      return;
    }
    final CartItem? cartItem = state.cartItemsById[menuItem.id];
    _logger.d('$_kTag addItem: ${menuItem.id}');
    _emitWith(
      menuItem.id,
      cartItem == null
          ? CartItem(menuItem: menuItem, quantity: 1)
          : cartItem.copyWith(quantity: cartItem.quantity + 1),
    );
  }

  void incrementItem(int menuItemId) {
    final CartItem? cartItem = state.cartItemsById[menuItemId];
    if (cartItem == null) {
      _logger.w('$_kTag incrementItem: $menuItemId not in cart, ignoring');
      return;
    }
    _logger.d('$_kTag incrementItem: $menuItemId');
    _emitWith(menuItemId, cartItem.copyWith(quantity: cartItem.quantity + 1));
  }

  /// Removes one of the item, and the item itself when it reaches zero.
  void decrementItem(int menuItemId) {
    final CartItem? cartItem = state.cartItemsById[menuItemId];
    if (cartItem == null) {
      _logger.w('$_kTag decrementItem: $menuItemId not in cart, ignoring');
      return;
    }
    _logger.d('$_kTag decrementItem: $menuItemId');
    _emitWith(
      menuItemId,
      cartItem.quantity > 1
          ? cartItem.copyWith(quantity: cartItem.quantity - 1)
          : null,
    );
  }

  void removeItem(int menuItemId) {
    if (!state.cartItemsById.containsKey(menuItemId)) {
      _logger.w('$_kTag removeItem: $menuItemId not in cart, ignoring');
      return;
    }
    _logger.d('$_kTag removeItem: $menuItemId');
    _emitWith(menuItemId, null);
  }

  void clearCart() {
    _logger.d('$_kTag clearCart');
    emit(const CartState());
  }

  /// Emits a new state with [cartItem] stored under [menuItemId], or removed
  /// when [cartItem] is null. The map is copied, so earlier states are never
  /// mutated.
  void _emitWith(int menuItemId, CartItem? cartItem) {
    final Map<int, CartItem> cartItemsById = Map<int, CartItem>.of(
      state.cartItemsById,
    );
    if (cartItem == null) {
      cartItemsById.remove(menuItemId);
    } else {
      cartItemsById[menuItemId] = cartItem;
    }
    emit(
      CartState(cartItemsById: Map<int, CartItem>.unmodifiable(cartItemsById)),
    );
  }
}
