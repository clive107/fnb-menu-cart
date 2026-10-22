import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/blocs/menu/menu_item_list/menu_item_list_bloc.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/screens/menu/menu_screen.dart';
import 'package:fnb_menu_cart/services/menu/menu_service.dart';
import 'package:fnb_menu_cart/utils/app/error_handling/get_failure_message.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockMenuService extends Mock implements MenuService {}

void main() {
  late MenuService mockMenuService;

  // No thumbnails, so the test makes no network requests.
  const Map<String, dynamic> fakeResponse = {
    'products': [
      {
        'id': 16,
        'title': 'Apple',
        'description': 'Fresh apple',
        'price': 1.99,
        'stock': 8,
        'availabilityStatus': 'In Stock',
        'tags': ['fruits'],
      },
      {
        'id': 34,
        'title': 'Nescafe Coffee',
        'description': 'Instant coffee',
        'price': 7.99,
        'stock': 0,
        'availabilityStatus': 'Out of Stock',
        'tags': ['beverages'],
      },
    ],
  };

  setUp(() {
    mockMenuService = MockMenuService();
  });

  // The Add button on the card for [name], so a tap doesn't depend on the
  // order the cards are listed in.
  Finder addButtonOn(String name) => find.descendant(
    of: find.widgetWithText(Card, name),
    matching: find.widgetWithText(FilledButton, 'Add'),
  );

  Future<void> pumpMenuScreen(WidgetTester tester) async {
    final Logger logger = Logger(level: Level.off);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<MenuItemListBloc>(
            create: (context) =>
                MenuItemListBloc(logger: logger, menuService: mockMenuService)
                  ..add(const GetMenuItemList()),
          ),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(logger: logger),
          ),
        ],
        child: const MaterialApp(home: MenuScreen()),
      ),
    );
  }

  testWidgets("Shows each item's name, description, price and availability.", (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Fresh apple'), findsOneWidget);
    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('Lists items under their category header.', (tester) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();

    // Vertical position of each text on screen; smaller is higher up.
    double topOf(String text) => tester.getTopLeft(find.text(text)).dy;

    // Top to bottom: Fruits header, Apple, Beverages header, Nescafe Coffee.
    expect(topOf('Fruits'), lessThan(topOf('Apple')));
    expect(topOf('Apple'), lessThan(topOf('Beverages')));
    expect(topOf('Beverages'), lessThan(topOf('Nescafe Coffee')));
  });

  testWidgets('Keeps the category header pinned while its items scroll.', (
    tester,
  ) async {
    // Enough fruits to scroll well within the Fruits section.
    final Map<String, dynamic> longResponse = {
      'products': [
        for (int id = 1; id <= 10; id++)
          {
            'id': id,
            'title': 'Fruit $id',
            'description': 'Fresh fruit',
            'price': 1.99,
            'stock': 8,
            'availabilityStatus': 'In Stock',
            'tags': ['fruits'],
          },
      ],
    };
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => longResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();
    final double headerTopBefore = tester.getTopLeft(find.text('Fruits')).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -300.0));
    await tester.pumpAndSettle();

    // The items moved up, but the header stayed where it was.
    expect(find.text('Fruit 1'), findsNothing);
    expect(tester.getTopLeft(find.text('Fruits')).dy, headerTopBefore);
  });

  testWidgets('Adding an item shows its quantity and the cart badge.', (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();
    await tester.tap(addButtonOn('Apple'));
    await tester.pump();

    // The Apple card now shows a stepper, and the badge counts 1.
    expect(find.byTooltip('Add one'), findsOneWidget);
    expect(find.byTooltip('Cart, 1 item'), findsOneWidget);
  });

  testWidgets('The card keeps its height when Add turns into the stepper.', (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();
    final Finder appleCard = find.widgetWithText(Card, 'Apple');
    final double heightBefore = tester.getSize(appleCard).height;
    await tester.tap(addButtonOn('Apple'));
    await tester.pump();

    expect(tester.getSize(appleCard).height, heightBefore);
  });

  testWidgets('Out-of-stock items look distinct and cannot be added.', (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Out of stock'), findsOneWidget);
    final FilledButton coffeeAddButton = tester.widget<FilledButton>(
      addButtonOn('Nescafe Coffee'),
    );
    expect(coffeeAddButton.onPressed, isNull);
  });

  testWidgets('Lays out without overflow on a narrow 320px phone.', (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320.0, 640.0);
    addTearDown(tester.view.reset);

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();
    // With a stepper showing, the widest state of the card.
    await tester.tap(addButtonOn('Apple'));
    await tester.pump();

    // A RenderFlex overflow would be reported here as an exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shows the error with a retry that reloads the menu.', (
    tester,
  ) async {
    when(
      () => mockMenuService.getMenuItemList(),
    ).thenThrow(const ClientExceptionFailure());

    await pumpMenuScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text(kClientExceptionMessage), findsOneWidget);

    when(
      () => mockMenuService.getMenuItemList(),
    ).thenAnswer((_) async => fakeResponse);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    verify(() => mockMenuService.getMenuItemList()).called(2);
  });
}
