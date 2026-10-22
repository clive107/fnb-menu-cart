import 'package:equatable/equatable.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';

/// A menu category and its items, in display order.
class MenuSection extends Equatable {
  final String category;
  final List<MenuItem> menuItemList;

  const MenuSection({required this.category, required this.menuItemList});

  @override
  List<Object?> get props => [category, menuItemList];
}
