part of 'menu_item_list_bloc.dart';

enum GetMenuItemListStatus { initial, loading, success, failure }

extension GetMenuItemListStatusX on GetMenuItemListStatus {
  bool get isInitial => this == GetMenuItemListStatus.initial;
  bool get isLoading => this == GetMenuItemListStatus.loading;
  bool get isSuccess => this == GetMenuItemListStatus.success;
  bool get isFailure => this == GetMenuItemListStatus.failure;
}

class MenuItemListState extends Equatable {
  final GetMenuItemListStatus getMenuItemListStatus;
  final Failure? getMenuItemListFailure;
  final List<MenuSection>? menuSectionList;

  const MenuItemListState({
    this.getMenuItemListStatus = GetMenuItemListStatus.initial,
    this.getMenuItemListFailure,
    this.menuSectionList,
  });

  @override
  List<Object?> get props => [
    getMenuItemListStatus,
    getMenuItemListFailure,
    menuSectionList,
  ];

  MenuItemListState copyWith({
    GetMenuItemListStatus? getMenuItemListStatus,
    Optional<Failure> getMenuItemListFailure = const Optional(),
    Optional<List<MenuSection>> menuSectionList = const Optional(),
  }) {
    return MenuItemListState(
      getMenuItemListStatus:
          getMenuItemListStatus ?? this.getMenuItemListStatus,
      getMenuItemListFailure: resolveOptional(
        getMenuItemListFailure,
        this.getMenuItemListFailure,
      ),
      menuSectionList: resolveOptional(menuSectionList, this.menuSectionList),
    );
  }
}
