import 'dart:io' show HttpStatus;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/blocs/menu/menu_item_list/menu_item_list_bloc.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/models/data_types/optional.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';
import 'package:fnb_menu_cart/models/menu/menu_section.dart';
import 'package:fnb_menu_cart/services/menu/menu_service.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockMenuService extends Mock implements MenuService {}

void main() {
  late Logger mockLogger;
  late MenuService mockMenuService;
  late MenuItemListBloc menuItemListBloc;

  // Products as returned by MenuService, under the `products` key. The
  // categories are interleaved to check that grouping keeps first-seen order.
  const Map<String, dynamic> fakeAppleJson = {
    'id': 16,
    'title': 'Apple',
    'description': 'Fresh apple',
    'price': 1.99,
    'stock': 8,
    'availabilityStatus': 'In Stock',
    'tags': ['fruits'],
  };
  const Map<String, dynamic> fakeJuiceJson = {
    'id': 29,
    'title': 'Juice',
    'description': 'Orange juice',
    'price': 3.99,
    'stock': 50,
    'availabilityStatus': 'In Stock',
    'tags': ['beverages'],
  };
  const Map<String, dynamic> fakeKiwiJson = {
    'id': 30,
    'title': 'Kiwi',
    'description': 'Green kiwi',
    'price': 2.49,
    'stock': 99,
    'availabilityStatus': 'In Stock',
    'tags': ['fruits'],
  };
  const Map<String, dynamic> fakeResponse = {
    'products': [fakeAppleJson, fakeJuiceJson, fakeKiwiJson],
  };
  final List<MenuSection> fakeMenuSectionList = [
    MenuSection(
      category: 'fruits',
      menuItemList: [
        MenuItem.fromJson(fakeAppleJson),
        MenuItem.fromJson(fakeKiwiJson),
      ],
    ),
    MenuSection(
      category: 'beverages',
      menuItemList: [MenuItem.fromJson(fakeJuiceJson)],
    ),
  ];

  setUp(() {
    mockLogger = MockLogger();
    mockMenuService = MockMenuService();
    menuItemListBloc = MenuItemListBloc(
      logger: mockLogger,
      menuService: mockMenuService,
    );
  });

  tearDown(() {
    menuItemListBloc.close();
  });

  test('Initial state is MenuItemListState()', () {
    expect(menuItemListBloc.state, const MenuItemListState());
  });

  group('[MenuItemListEvent] tests -', () {
    test('GetMenuItemList has empty props.', () {
      expect(const GetMenuItemList().props, isEmpty);
    });
  });

  group('[GetMenuItemListStatusX] tests -', () {
    test('isInitial is true only for initial status.', () {
      expect(GetMenuItemListStatus.initial.isInitial, isTrue);
      expect(GetMenuItemListStatus.loading.isInitial, isFalse);
      expect(GetMenuItemListStatus.success.isInitial, isFalse);
      expect(GetMenuItemListStatus.failure.isInitial, isFalse);
    });

    test('isLoading is true only for loading status.', () {
      expect(GetMenuItemListStatus.loading.isLoading, isTrue);
      expect(GetMenuItemListStatus.initial.isLoading, isFalse);
      expect(GetMenuItemListStatus.success.isLoading, isFalse);
      expect(GetMenuItemListStatus.failure.isLoading, isFalse);
    });

    test('isSuccess is true only for success status.', () {
      expect(GetMenuItemListStatus.success.isSuccess, isTrue);
      expect(GetMenuItemListStatus.initial.isSuccess, isFalse);
      expect(GetMenuItemListStatus.loading.isSuccess, isFalse);
      expect(GetMenuItemListStatus.failure.isSuccess, isFalse);
    });

    test('isFailure is true only for failure status.', () {
      expect(GetMenuItemListStatus.failure.isFailure, isTrue);
      expect(GetMenuItemListStatus.initial.isFailure, isFalse);
      expect(GetMenuItemListStatus.loading.isFailure, isFalse);
      expect(GetMenuItemListStatus.success.isFailure, isFalse);
    });
  });

  group('[MenuItemListState.copyWith] tests -', () {
    const Failure fakeFailure = Failure(statusCode: 500, message: 'error');

    test('preserves all fields when called with no arguments.', () {
      final MenuItemListState state = MenuItemListState(
        getMenuItemListStatus: GetMenuItemListStatus.failure,
        getMenuItemListFailure: fakeFailure,
        menuSectionList: fakeMenuSectionList,
      );
      expect(state.copyWith(), state);
    });

    test('updates getMenuItemListStatus when provided.', () {
      const MenuItemListState state = MenuItemListState();
      expect(
        state
            .copyWith(getMenuItemListStatus: GetMenuItemListStatus.loading)
            .getMenuItemListStatus,
        GetMenuItemListStatus.loading,
      );
    });

    test(
      'updates getMenuItemListFailure to a value when Optional.set(value) is provided.',
      () {
        const MenuItemListState state = MenuItemListState();
        expect(
          state
              .copyWith(getMenuItemListFailure: Optional.set(fakeFailure))
              .getMenuItemListFailure,
          fakeFailure,
        );
      },
    );

    test(
      'clears getMenuItemListFailure to null when Optional.set(null) is provided.',
      () {
        const MenuItemListState state = MenuItemListState(
          getMenuItemListFailure: fakeFailure,
        );
        expect(
          state
              .copyWith(getMenuItemListFailure: const Optional.set(null))
              .getMenuItemListFailure,
          isNull,
        );
      },
    );

    test(
      'preserves existing getMenuItemListFailure when Optional() is not provided.',
      () {
        const MenuItemListState state = MenuItemListState(
          getMenuItemListFailure: fakeFailure,
        );
        expect(state.copyWith().getMenuItemListFailure, fakeFailure);
      },
    );

    test(
      'updates menuSectionList to a value when Optional.set(value) is provided.',
      () {
        const MenuItemListState state = MenuItemListState();
        expect(
          state
              .copyWith(menuSectionList: Optional.set(fakeMenuSectionList))
              .menuSectionList,
          fakeMenuSectionList,
        );
      },
    );

    test(
      'clears menuSectionList to null when Optional.set(null) is provided.',
      () {
        final MenuItemListState state = MenuItemListState(
          menuSectionList: fakeMenuSectionList,
        );
        expect(
          state
              .copyWith(menuSectionList: const Optional.set(null))
              .menuSectionList,
          isNull,
        );
      },
    );

    test(
      'preserves existing menuSectionList when Optional() is not provided.',
      () {
        final MenuItemListState state = MenuItemListState(
          menuSectionList: fakeMenuSectionList,
        );
        expect(state.copyWith().menuSectionList, fakeMenuSectionList);
      },
    );
  });

  group('[GetMenuItemList] tests -', () {
    // Scenario - Success
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Emits [loading, success] with sections grouped by category in first-seen order when [GetMenuItemList] is added and the request succeeds.',
      build: () {
        when(
          () => mockMenuService.getMenuItemList(),
        ).thenAnswer((_) async => fakeResponse);
        return menuItemListBloc;
      },
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => [
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.loading,
          getMenuItemListFailure: null,
          menuSectionList: null,
        ),
        MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.success,
          getMenuItemListFailure: null,
          menuSectionList: fakeMenuSectionList,
        ),
      ],
      verify: (_) {
        verify(() => mockMenuService.getMenuItemList()).called(1);
      },
    );

    // Scenario - Reload keeps the sections already showing
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Keeps the current sections while loading when [GetMenuItemList] is added again.',
      build: () {
        when(
          () => mockMenuService.getMenuItemList(),
        ).thenAnswer((_) async => fakeResponse);
        return menuItemListBloc;
      },
      seed: () => MenuItemListState(
        getMenuItemListStatus: GetMenuItemListStatus.success,
        getMenuItemListFailure: null,
        menuSectionList: fakeMenuSectionList,
      ),
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => [
        MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.loading,
          getMenuItemListFailure: null,
          menuSectionList: fakeMenuSectionList,
        ),
        MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.success,
          getMenuItemListFailure: null,
          menuSectionList: fakeMenuSectionList,
        ),
      ],
    );

    // Scenario - Known Failure
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Emits [loading, failure] with the failure when [GetMenuItemList] is added and throws a Failure.',
      build: () {
        when(
          () => mockMenuService.getMenuItemList(),
        ).thenThrow(const ClientExceptionFailure());
        return menuItemListBloc;
      },
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => [
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.loading,
          getMenuItemListFailure: null,
          menuSectionList: null,
        ),
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.failure,
          getMenuItemListFailure: ClientExceptionFailure(),
          menuSectionList: null,
        ),
      ],
    );

    // Scenario - Unexpected JSON shape
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Emits [loading, failure] with a bad-format failure when [GetMenuItemList] is added and a product is missing fields.',
      build: () {
        when(() => mockMenuService.getMenuItemList()).thenAnswer(
          (_) async => {
            'products': [
              {'id': 1},
            ],
          },
        );
        return menuItemListBloc;
      },
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => [
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.loading,
          getMenuItemListFailure: null,
          menuSectionList: null,
        ),
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.failure,
          getMenuItemListFailure: Failure(
            statusCode: HttpStatus.ok,
            errorCode: kBadFormatFailure,
          ),
          menuSectionList: null,
        ),
      ],
    );

    // Scenario - Unexpected exception
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Emits [loading, failure] with null failure when [GetMenuItemList] is added and throws an unexpected exception.',
      build: () {
        when(
          () => mockMenuService.getMenuItemList(),
        ).thenThrow(Exception('Unexpected error'));
        return menuItemListBloc;
      },
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => [
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.loading,
          getMenuItemListFailure: null,
          menuSectionList: null,
        ),
        const MenuItemListState(
          getMenuItemListStatus: GetMenuItemListStatus.failure,
          getMenuItemListFailure: null,
          menuSectionList: null,
        ),
      ],
    );

    // Scenario - Already loading
    blocTest<MenuItemListBloc, MenuItemListState>(
      'Emits nothing and skips the request when [GetMenuItemList] is added while already loading.',
      build: () => menuItemListBloc,
      seed: () => const MenuItemListState(
        getMenuItemListStatus: GetMenuItemListStatus.loading,
        getMenuItemListFailure: null,
        menuSectionList: null,
      ),
      act: (bloc) => bloc.add(const GetMenuItemList()),
      expect: () => <MenuItemListState>[],
      verify: (_) {
        verifyNever(() => mockMenuService.getMenuItemList());
      },
    );
  });
}
