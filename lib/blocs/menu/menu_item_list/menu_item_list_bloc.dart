import 'dart:io' show HttpStatus;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/models/data_types/optional.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';
import 'package:fnb_menu_cart/models/menu/menu_section.dart';
import 'package:fnb_menu_cart/services/menu/menu_service.dart';
import 'package:fnb_menu_cart/utils/data_types/optional.dart';
import 'package:logger/logger.dart';

part 'menu_item_list_event.dart';
part 'menu_item_list_state.dart';

class MenuItemListBloc extends Bloc<MenuItemListEvent, MenuItemListState> {
  static const String _kTag = '[MenuItemListBloc]';

  final Logger _logger;
  final MenuService _menuService;

  MenuItemListBloc({required Logger logger, required MenuService menuService})
    : _logger = logger,
      _menuService = menuService,
      super(const MenuItemListState()) {
    on<GetMenuItemList>(_mapGetMenuItemListEventToState);
  }

  // Retrieves the menu and groups it into sections by category.
  void _mapGetMenuItemListEventToState(
    GetMenuItemList event,
    Emitter<MenuItemListState> emit,
  ) async {
    const String kTag = '$_kTag[GetMenuItemList]';
    // Check if the state is already loading, to prevent duplicate requests
    if (state.getMenuItemListStatus.isLoading) {
      _logger.w('$kTag Already loading, ignoring request');
      return;
    }
    // Emit state with loading status. The current sections are kept, so a
    // reload doesn't blank a menu that's already showing.
    emit(
      state.copyWith(
        getMenuItemListStatus: GetMenuItemListStatus.loading,
        getMenuItemListFailure: const Optional.set(null),
      ),
    );
    try {
      _logger.i('$kTag Getting menu item list...');
      final Map<String, dynamic> response = await _menuService
          .getMenuItemList();
      final List<dynamic> data =
          response['products'] as List<dynamic>? ?? const [];
      final List<MenuItem> menuItemList = data
          .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _logger.i(
        '$kTag Get menu item list successfully, length: ${menuItemList.length}',
      );
      // Emit state with success status and data
      emit(
        state.copyWith(
          getMenuItemListStatus: GetMenuItemListStatus.success,
          getMenuItemListFailure: const Optional.set(null),
          menuSectionList: Optional.set(_groupByCategory(menuItemList)),
        ),
      );
    } catch (e) {
      _logger.e('$kTag Get menu item list failed: $e');
      // ApiClient turns network and HTTP errors into a Failure. A TypeError
      // here means the JSON didn't have the expected shape (e.g. a missing
      // price), so it's shown as a bad-format error. Anything else has no
      // failure to show, so the UI falls back to a generic message.
      final Failure? failure = switch (e) {
        Failure() => e,
        TypeError() => const Failure(
          statusCode: HttpStatus.ok,
          errorCode: kBadFormatFailure,
        ),
        _ => null,
      };
      // Emit state with failure status and failure
      emit(
        state.copyWith(
          getMenuItemListStatus: GetMenuItemListStatus.failure,
          getMenuItemListFailure: Optional.set(failure),
        ),
      );
    }
  }

  /// Groups items by category, keeping the order in which each category and
  /// item first appears. Done once per fetch, not on every rebuild.
  List<MenuSection> _groupByCategory(List<MenuItem> menuItemList) {
    final Map<String, List<MenuItem>> itemsByCategory = {};
    for (final MenuItem menuItem in menuItemList) {
      itemsByCategory.putIfAbsent(menuItem.category, () => []).add(menuItem);
    }
    return [
      for (final MapEntry<String, List<MenuItem>> entry
          in itemsByCategory.entries)
        MenuSection(category: entry.key, menuItemList: entry.value),
    ];
  }
}
