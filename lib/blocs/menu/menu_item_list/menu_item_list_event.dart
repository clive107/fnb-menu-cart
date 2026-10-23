part of 'menu_item_list_bloc.dart';

abstract class MenuItemListEvent extends Equatable {
  const MenuItemListEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches the menu. Also used to retry after a failure.
class GetMenuItemList extends MenuItemListEvent {
  const GetMenuItemList();
}
