import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/app.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/services/app/api_client.dart';
import 'package:fnb_menu_cart/utils/app/error_handling/get_failure_message.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late ApiClient mockApiClient;

  // Grocery products as DummyJSON returns them. Neither ID is in the demo
  // out-of-stock set, and there are no thumbnails, so no network requests.
  const Map<String, dynamic> fakeMenuResponse = {
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
        'id': 29,
        'title': 'Juice',
        'description': 'Orange juice',
        'price': 3.99,
        'stock': 50,
        'availabilityStatus': 'In Stock',
        'tags': ['beverages'],
      },
    ],
  };
  const Map<String, dynamic> fakeOrderResponse = {'id': 209};

  setUp(() {
    mockApiClient = MockApiClient();
    when(
      () => mockApiClient.jsonGet(any(), query: any(named: 'query')),
    ).thenAnswer((_) async => fakeMenuResponse);
  });

  /* Section - Helpers */
  // Runs the real app with only the API client mocked, so services, blocs,
  // the app-level checkout listener and navigation are all real.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        apiClient: mockApiClient,
        logger: Logger(level: Level.off),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The Add button on the menu card for [name].
  Finder addButtonOn(String name) => find.descendant(
    of: find.widgetWithText(Card, name),
    matching: find.bySubtype<FilledButton>(),
  );

  // A button with [tooltip] inside the cart tile for [name].
  Finder buttonInTile(String name, String tooltip) => find.descendant(
    of: find.widgetWithText(Card, name),
    matching: find.byTooltip(tooltip),
  );

  // The IconButton itself (byTooltip finds the tooltip inside it), to check
  // whether it's enabled.
  IconButton iconButtonInTile(
    WidgetTester tester,
    String name,
    String tooltip,
  ) => tester.widget<IconButton>(
    find.ancestor(
      of: buttonInTile(name, tooltip),
      matching: find.bySubtype<IconButton>(),
    ),
  );

  Future<void> openCart(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
  }

  // Adds two Apples and one Juice, then opens the cart. Total: $7.97.
  Future<void> addItemsAndOpenCart(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(addButtonOn('Apple'));
    await tester.pump();
    await tester.tap(buttonInTile('Apple', 'Add one'));
    await tester.pump();
    await tester.tap(addButtonOn('Juice'));
    await tester.pump();
    await openCart(tester);
  }

  testWidgets('Shows each item with its prices, and the total.', (
    tester,
  ) async {
    await addItemsAndOpenCart(tester);

    expect(find.widgetWithText(AppBar, 'Cart'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text(r'$3.98'), findsOneWidget); // 2 x $1.99
    expect(find.text(r'$1.99 each'), findsOneWidget);
    expect(find.text('Juice'), findsOneWidget);
    expect(find.text(r'$7.97'), findsOneWidget);
  });

  testWidgets('Quantity controls and remove update the total.', (tester) async {
    await addItemsAndOpenCart(tester);

    await tester.tap(buttonInTile('Juice', 'Add one'));
    await tester.pump();
    expect(find.text(r'$11.96'), findsOneWidget); // 2 x $1.99 + 2 x $3.99

    await tester.tap(buttonInTile('Juice', 'Remove'));
    await tester.pump();
    expect(find.text('Juice'), findsNothing);
    expect(find.text(r'$3.98'), findsNWidgets(2)); // Apple subtotal and total

    await tester.tap(buttonInTile('Apple', 'Remove one'));
    await tester.pump();
    await tester.tap(buttonInTile('Apple', 'Remove one'));
    await tester.pump();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('An empty cart offers a way back to the menu.', (tester) async {
    await pumpApp(tester);
    await openCart(tester);

    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Browse menu'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Menu'), findsOneWidget);
  });

  testWidgets(
    'Placing an order locks the cart, then confirms, empties the cart and returns to the menu.',
    (tester) async {
      final Completer<Map<String, dynamic>> orderCompleter =
          Completer<Map<String, dynamic>>();
      when(
        () => mockApiClient.jsonPost(any(), body: any(named: 'body')),
      ).thenAnswer((_) => orderCompleter.future);
      await addItemsAndOpenCart(tester);

      await tester.tap(find.text('Place order'));
      await tester.pump();

      // In flight: button disabled with a spinner, cart controls locked.
      expect(find.text('Placing order…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(iconButtonInTile(tester, 'Apple', 'Add one').onPressed, isNull);
      expect(iconButtonInTile(tester, 'Apple', 'Remove').onPressed, isNull);

      orderCompleter.complete(fakeOrderResponse);
      await tester.pumpAndSettle();
      expect(find.text('Order placed'), findsOneWidget);
      expect(find.textContaining('#209'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Menu'), findsOneWidget);
      // The badge is gone: the cart is empty.
      expect(find.byTooltip('Cart'), findsOneWidget);
      verify(
        () => mockApiClient.jsonPost(
          'carts/add',
          body: {
            'userId': 1,
            'products': [
              {'id': 16, 'quantity': 2},
              {'id': 29, 'quantity': 1},
            ],
          },
        ),
      ).called(1);
    },
  );

  testWidgets('A failed order shows the error and keeps the cart.', (
    tester,
  ) async {
    when(
      () => mockApiClient.jsonPost(any(), body: any(named: 'body')),
    ).thenThrow(const TimeoutFailure());
    await addItemsAndOpenCart(tester);

    await tester.tap(find.text('Place order'));
    await tester.pump();
    await tester.pump();

    expect(find.text(kTimeoutMessage), findsOneWidget);
    expect(find.text(r'$7.97'), findsOneWidget);
    // Place Order is the retry, so it's enabled again.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Place order'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'Leaving the cart mid-order still confirms the order and empties the cart.',
    (tester) async {
      final Completer<Map<String, dynamic>> orderCompleter =
          Completer<Map<String, dynamic>>();
      when(
        () => mockApiClient.jsonPost(any(), body: any(named: 'body')),
      ).thenAnswer((_) => orderCompleter.future);
      await addItemsAndOpenCart(tester);

      await tester.tap(find.text('Place order'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Menu'), findsOneWidget);

      orderCompleter.complete(fakeOrderResponse);
      await tester.pumpAndSettle();
      expect(find.text('Order placed'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Cart'), findsOneWidget);
    },
  );

  testWidgets('Lays out without overflow on a narrow 320px phone.', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320.0, 640.0);
    addTearDown(tester.view.reset);

    await addItemsAndOpenCart(tester);

    // A RenderFlex overflow would be reported here as an exception.
    expect(tester.takeException(), isNull);
  });
}
