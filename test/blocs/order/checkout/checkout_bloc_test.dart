import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/blocs/order/checkout/checkout_bloc.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/models/data_types/optional.dart';
import 'package:fnb_menu_cart/services/order/order_service.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockOrderService extends Mock implements OrderService {}

void main() {
  late Logger mockLogger;
  late OrderService mockOrderService;
  late CheckoutBloc checkoutBloc;

  const PlaceOrderRequest fakeRequest = PlaceOrderRequest(
    quantityByItemId: {16: 2, 29: 1},
  );
  // The carts/add response, trimmed to the fields the bloc reads.
  const Map<String, dynamic> fakeResponse = {'id': 209, 'totalQuantity': 3};

  setUpAll(() {
    registerFallbackValue(const PlaceOrderRequest(quantityByItemId: {}));
  });

  setUp(() {
    mockLogger = MockLogger();
    mockOrderService = MockOrderService();
    checkoutBloc = CheckoutBloc(
      logger: mockLogger,
      orderService: mockOrderService,
    );
  });

  tearDown(() {
    checkoutBloc.close();
  });

  test('Initial state is CheckoutState()', () {
    expect(checkoutBloc.state, const CheckoutState());
  });

  group('[CheckoutEvent] tests -', () {
    test('PlaceOrder exposes its request in props.', () {
      expect(const PlaceOrder(placeOrderRequest: fakeRequest).props, [
        fakeRequest,
      ]);
    });

    test('ResetCheckout has empty props.', () {
      expect(const ResetCheckout().props, isEmpty);
    });
  });

  group('[PlaceOrderStatusX] tests -', () {
    test('isInitial is true only for initial status.', () {
      expect(PlaceOrderStatus.initial.isInitial, isTrue);
      expect(PlaceOrderStatus.loading.isInitial, isFalse);
      expect(PlaceOrderStatus.success.isInitial, isFalse);
      expect(PlaceOrderStatus.failure.isInitial, isFalse);
    });

    test('isLoading is true only for loading status.', () {
      expect(PlaceOrderStatus.loading.isLoading, isTrue);
      expect(PlaceOrderStatus.initial.isLoading, isFalse);
      expect(PlaceOrderStatus.success.isLoading, isFalse);
      expect(PlaceOrderStatus.failure.isLoading, isFalse);
    });

    test('isSuccess is true only for success status.', () {
      expect(PlaceOrderStatus.success.isSuccess, isTrue);
      expect(PlaceOrderStatus.initial.isSuccess, isFalse);
      expect(PlaceOrderStatus.loading.isSuccess, isFalse);
      expect(PlaceOrderStatus.failure.isSuccess, isFalse);
    });

    test('isFailure is true only for failure status.', () {
      expect(PlaceOrderStatus.failure.isFailure, isTrue);
      expect(PlaceOrderStatus.initial.isFailure, isFalse);
      expect(PlaceOrderStatus.loading.isFailure, isFalse);
      expect(PlaceOrderStatus.success.isFailure, isFalse);
    });
  });

  group('[CheckoutState.copyWith] tests -', () {
    const Failure fakeFailure = Failure(statusCode: 500, message: 'error');

    test('preserves all fields when called with no arguments.', () {
      const CheckoutState state = CheckoutState(
        placeOrderStatus: PlaceOrderStatus.failure,
        placeOrderFailure: fakeFailure,
        orderId: 209,
      );
      expect(state.copyWith(), state);
    });

    test('updates placeOrderStatus when provided.', () {
      const CheckoutState state = CheckoutState();
      expect(
        state
            .copyWith(placeOrderStatus: PlaceOrderStatus.loading)
            .placeOrderStatus,
        PlaceOrderStatus.loading,
      );
    });

    test(
      'updates placeOrderFailure to a value when Optional.set(value) is provided.',
      () {
        const CheckoutState state = CheckoutState();
        expect(
          state
              .copyWith(placeOrderFailure: Optional.set(fakeFailure))
              .placeOrderFailure,
          fakeFailure,
        );
      },
    );

    test(
      'clears placeOrderFailure to null when Optional.set(null) is provided.',
      () {
        const CheckoutState state = CheckoutState(
          placeOrderFailure: fakeFailure,
        );
        expect(
          state
              .copyWith(placeOrderFailure: const Optional.set(null))
              .placeOrderFailure,
          isNull,
        );
      },
    );

    test(
      'preserves existing placeOrderFailure when Optional() is not provided.',
      () {
        const CheckoutState state = CheckoutState(
          placeOrderFailure: fakeFailure,
        );
        expect(state.copyWith().placeOrderFailure, fakeFailure);
      },
    );

    test('updates orderId when Optional.set(value) is provided.', () {
      const CheckoutState state = CheckoutState();
      expect(state.copyWith(orderId: const Optional.set(209)).orderId, 209);
    });

    test('clears orderId to null when Optional.set(null) is provided.', () {
      const CheckoutState state = CheckoutState(orderId: 209);
      expect(state.copyWith(orderId: const Optional.set(null)).orderId, isNull);
    });

    test('preserves existing orderId when Optional() is not provided.', () {
      const CheckoutState state = CheckoutState(orderId: 209);
      expect(state.copyWith().orderId, 209);
    });
  });

  group('[PlaceOrder] tests -', () {
    // Scenario - Success
    blocTest<CheckoutBloc, CheckoutState>(
      'Emits [loading, success] with the order ID when [PlaceOrder] is added and the request succeeds.',
      build: () {
        when(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).thenAnswer((_) async => fakeResponse);
        return checkoutBloc;
      },
      act: (bloc) => bloc.add(const PlaceOrder(placeOrderRequest: fakeRequest)),
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.loading,
          placeOrderFailure: null,
          orderId: null,
        ),
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.success,
          placeOrderFailure: null,
          orderId: 209,
        ),
      ],
      verify: (_) {
        verify(
          () => mockOrderService.placeOrder(placeOrderRequest: fakeRequest),
        ).called(1);
      },
    );

    // Scenario - Retry after a failure clears the old failure
    blocTest<CheckoutBloc, CheckoutState>(
      'Clears the previous failure when [PlaceOrder] is added after a failure.',
      build: () {
        when(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).thenAnswer((_) async => fakeResponse);
        return checkoutBloc;
      },
      seed: () => const CheckoutState(
        placeOrderStatus: PlaceOrderStatus.failure,
        placeOrderFailure: TimeoutFailure(),
        orderId: null,
      ),
      act: (bloc) => bloc.add(const PlaceOrder(placeOrderRequest: fakeRequest)),
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.loading,
          placeOrderFailure: null,
          orderId: null,
        ),
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.success,
          placeOrderFailure: null,
          orderId: 209,
        ),
      ],
    );

    // Scenario - Known Failure
    blocTest<CheckoutBloc, CheckoutState>(
      'Emits [loading, failure] with the failure when [PlaceOrder] is added and throws a Failure.',
      build: () {
        when(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).thenThrow(const TimeoutFailure());
        return checkoutBloc;
      },
      act: (bloc) => bloc.add(const PlaceOrder(placeOrderRequest: fakeRequest)),
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.loading,
          placeOrderFailure: null,
          orderId: null,
        ),
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.failure,
          placeOrderFailure: TimeoutFailure(),
          orderId: null,
        ),
      ],
    );

    // Scenario - Unexpected exception
    blocTest<CheckoutBloc, CheckoutState>(
      'Emits [loading, failure] with null failure when [PlaceOrder] is added and throws an unexpected exception.',
      build: () {
        when(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).thenThrow(Exception('Unexpected error'));
        return checkoutBloc;
      },
      act: (bloc) => bloc.add(const PlaceOrder(placeOrderRequest: fakeRequest)),
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.loading,
          placeOrderFailure: null,
          orderId: null,
        ),
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.failure,
          placeOrderFailure: null,
          orderId: null,
        ),
      ],
    );

    // Scenario - Already placing an order
    blocTest<CheckoutBloc, CheckoutState>(
      'Emits nothing and skips the request when [PlaceOrder] is added while an order is in flight.',
      build: () => checkoutBloc,
      seed: () => const CheckoutState(
        placeOrderStatus: PlaceOrderStatus.loading,
        placeOrderFailure: null,
        orderId: null,
      ),
      act: (bloc) => bloc.add(const PlaceOrder(placeOrderRequest: fakeRequest)),
      expect: () => <CheckoutState>[],
      verify: (_) {
        verifyNever(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        );
      },
    );

    // Scenario - Double tap while the first request is in flight. The
    // response is held back until both taps are in, as with a real network
    // call; an instant fake would finish the first order before the second
    // tap is processed.
    final Completer<Map<String, dynamic>> responseCompleter =
        Completer<Map<String, dynamic>>();
    blocTest<CheckoutBloc, CheckoutState>(
      'Places only one order when [PlaceOrder] is added twice while the first is in flight.',
      build: () {
        when(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).thenAnswer((_) => responseCompleter.future);
        return checkoutBloc;
      },
      act: (bloc) async {
        bloc
          ..add(const PlaceOrder(placeOrderRequest: fakeRequest))
          ..add(const PlaceOrder(placeOrderRequest: fakeRequest));
        await Future<void>.delayed(Duration.zero);
        responseCompleter.complete(fakeResponse);
      },
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.loading,
          placeOrderFailure: null,
          orderId: null,
        ),
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.success,
          placeOrderFailure: null,
          orderId: 209,
        ),
      ],
      verify: (_) {
        verify(
          () => mockOrderService.placeOrder(
            placeOrderRequest: any(named: 'placeOrderRequest'),
          ),
        ).called(1);
      },
    );
  });

  group('[ResetCheckout] tests -', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'Emits the initial state when [ResetCheckout] is added after a result.',
      build: () => checkoutBloc,
      seed: () => const CheckoutState(
        placeOrderStatus: PlaceOrderStatus.success,
        placeOrderFailure: null,
        orderId: 209,
      ),
      act: (bloc) => bloc.add(const ResetCheckout()),
      expect: () => [
        const CheckoutState(
          placeOrderStatus: PlaceOrderStatus.initial,
          placeOrderFailure: null,
          orderId: null,
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'Emits nothing when [ResetCheckout] is added while an order is in flight.',
      build: () => checkoutBloc,
      seed: () => const CheckoutState(
        placeOrderStatus: PlaceOrderStatus.loading,
        placeOrderFailure: null,
        orderId: null,
      ),
      act: (bloc) => bloc.add(const ResetCheckout()),
      expect: () => <CheckoutState>[],
    );
  });
}
