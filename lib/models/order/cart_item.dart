import 'package:equatable/equatable.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';

class CartItem extends Equatable {
  final MenuItem menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  int get subtotalInCents => menuItem.priceInCents * quantity;

  /// True when no more can be added without exceeding the available stock.
  bool get isAtStockLimit => quantity >= menuItem.stock;

  @override
  List<Object?> get props => [menuItem, quantity];

  CartItem copyWith({int? quantity}) {
    return CartItem(menuItem: menuItem, quantity: quantity ?? this.quantity);
  }
}
