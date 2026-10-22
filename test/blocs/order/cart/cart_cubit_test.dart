import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/blocs/order/cart/cart_cubit.dart';
import 'package:fnb_menu_cart/enums/menu/menu_item_availability.dart';
import 'package:fnb_menu_cart/models/menu/menu_item.dart';
import 'package:fnb_menu_cart/models/order/cart_item.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  late Logger mockLogger;
  late CartCubit cartCubit;

  const MenuItem fakeApple = MenuItem(
    id: 16,
    name: 'Apple',
    description: 'Fresh apple',
    priceInCents: 199,
    category: 'fruits',
    availability: MenuItemAvailability.inStock,
  );
  const MenuItem fakeJuice = MenuItem(
    id: 29,
    name: 'Juice',
    description: 'Orange juice',
    priceInCents: 399,
    category: 'beverages',
    availability: MenuItemAvailability.lowStock,
  );
  const MenuItem fakeCoffee = MenuItem(
    id: 34,
    name: 'Nescafe Coffee',
    description: 'Instant coffee',
    priceInCents: 799,
    category: 'beverages',
    availability: MenuItemAvailability.outOfStock,
  );

  setUp(() {
    mockLogger = MockLogger();
    cartCubit = CartCubit(logger: mockLogger);
  });

  tearDown(() {
    cartCubit.close();
  });

  test('Initial state is an empty CartState()', () {
    expect(cartCubit.state, const CartState(cartItemsById: {}));
  });

  group('[CartState] derived values tests -', () {
    const CartState fakeState = CartState(
      cartItemsById: {
        16: CartItem(menuItem: fakeApple, quantity: 2),
        29: CartItem(menuItem: fakeJuice, quantity: 1),
      },
    );

    test('quantityByItemId maps each item ID to its quantity.', () {
      expect(fakeState.quantityByItemId, {16: 2, 29: 1});
      expect(const CartState(cartItemsById: {}).quantityByItemId, isEmpty);
    });

    test('cartItemList returns the items in the order they were added.', () {
      expect(fakeState.cartItemList, const [
        CartItem(menuItem: fakeApple, quantity: 2),
        CartItem(menuItem: fakeJuice, quantity: 1),
      ]);
    });

    test('isEmpty is true only when the cart has no items.', () {
      expect(const CartState(cartItemsById: {}).isEmpty, isTrue);
      expect(fakeState.isEmpty, isFalse);
    });

    test('totalQuantity sums the quantities of all items.', () {
      expect(fakeState.totalQuantity, 3);
      expect(const CartState(cartItemsById: {}).totalQuantity, 0);
    });

    test('totalInCents sums price x quantity for all items.', () {
      // 199 x 2 + 399 x 1
      expect(fakeState.totalInCents, 797);
      expect(const CartState(cartItemsById: {}).totalInCents, 0);
    });

    test(
      'quantityOf returns the quantity, or 0 for an item not in the cart.',
      () {
        expect(fakeState.quantityOf(16), 2);
        expect(fakeState.quantityOf(34), 0);
      },
    );
  });

  group('[addItem] tests -', () {
    blocTest<CartCubit, CartState>(
      'Adds the item with quantity 1 when it is not in the cart.',
      build: () => cartCubit,
      act: (cubit) => cubit.addItem(fakeApple),
      expect: () => [
        const CartState(
          cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 1)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Increases the quantity by 1 when the item is already in the cart.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 1)},
      ),
      act: (cubit) => cubit.addItem(fakeApple),
      expect: () => [
        const CartState(
          cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 2)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Adds a low-stock item.',
      build: () => cartCubit,
      act: (cubit) => cubit.addItem(fakeJuice),
      expect: () => [
        const CartState(
          cartItemsById: {29: CartItem(menuItem: fakeJuice, quantity: 1)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Emits nothing when the item is out of stock.',
      build: () => cartCubit,
      act: (cubit) => cubit.addItem(fakeCoffee),
      expect: () => <CartState>[],
    );
  });

  group('[incrementItem] tests -', () {
    blocTest<CartCubit, CartState>(
      'Increases the quantity by 1 when the item is in the cart.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 1)},
      ),
      act: (cubit) => cubit.incrementItem(16),
      expect: () => [
        const CartState(
          cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 2)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Emits nothing when the item is not in the cart.',
      build: () => cartCubit,
      act: (cubit) => cubit.incrementItem(16),
      expect: () => <CartState>[],
    );
  });

  group('[decrementItem] tests -', () {
    blocTest<CartCubit, CartState>(
      'Decreases the quantity by 1 when the quantity is above 1.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 2)},
      ),
      act: (cubit) => cubit.decrementItem(16),
      expect: () => [
        const CartState(
          cartItemsById: {16: CartItem(menuItem: fakeApple, quantity: 1)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Removes the item when its quantity is 1.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {
          16: CartItem(menuItem: fakeApple, quantity: 1),
          29: CartItem(menuItem: fakeJuice, quantity: 1),
        },
      ),
      act: (cubit) => cubit.decrementItem(16),
      expect: () => [
        const CartState(
          cartItemsById: {29: CartItem(menuItem: fakeJuice, quantity: 1)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Emits nothing when the item is not in the cart.',
      build: () => cartCubit,
      act: (cubit) => cubit.decrementItem(16),
      expect: () => <CartState>[],
    );
  });

  group('[removeItem] tests -', () {
    blocTest<CartCubit, CartState>(
      'Removes the item whatever its quantity.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {
          16: CartItem(menuItem: fakeApple, quantity: 3),
          29: CartItem(menuItem: fakeJuice, quantity: 1),
        },
      ),
      act: (cubit) => cubit.removeItem(16),
      expect: () => [
        const CartState(
          cartItemsById: {29: CartItem(menuItem: fakeJuice, quantity: 1)},
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'Emits nothing when the item is not in the cart.',
      build: () => cartCubit,
      act: (cubit) => cubit.removeItem(16),
      expect: () => <CartState>[],
    );
  });

  group('[clearCart] tests -', () {
    blocTest<CartCubit, CartState>(
      'Empties the cart.',
      build: () => cartCubit,
      seed: () => const CartState(
        cartItemsById: {
          16: CartItem(menuItem: fakeApple, quantity: 2),
          29: CartItem(menuItem: fakeJuice, quantity: 1),
        },
      ),
      act: (cubit) => cubit.clearCart(),
      expect: () => [const CartState(cartItemsById: {})],
    );
  });

  test('Earlier states are not mutated by later changes.', () {
    cartCubit.addItem(fakeApple);
    final CartState firstState = cartCubit.state;
    cartCubit.addItem(fakeJuice);

    expect(firstState.cartItemsById.keys, [16]);
    expect(
      () => cartCubit.state.cartItemsById[99] = const CartItem(
        menuItem: fakeApple,
        quantity: 1,
      ),
      throwsUnsupportedError,
    );
  });
}
