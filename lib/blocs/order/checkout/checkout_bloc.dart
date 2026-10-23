import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/models/data_types/optional.dart';
import 'package:fnb_menu_cart/services/order/order_service.dart';
import 'package:fnb_menu_cart/utils/data_types/optional.dart';
import 'package:logger/logger.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

/// Places orders. Provided above MaterialApp, so a request in flight keeps
/// going, and its result is still handled, if the user leaves the cart screen.
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  static const String _kTag = '[CheckoutBloc]';

  final Logger _logger;
  final OrderService _orderService;

  CheckoutBloc({required Logger logger, required OrderService orderService})
    : _logger = logger,
      _orderService = orderService,
      super(const CheckoutState()) {
    on<PlaceOrder>(_mapPlaceOrderEventToState);
    on<ResetCheckout>(_mapResetCheckoutEventToState);
  }

  void _mapPlaceOrderEventToState(
    PlaceOrder event,
    Emitter<CheckoutState> emit,
  ) async {
    const String kTag = '$_kTag[PlaceOrder]';
    // Double-submit guard: ignore new orders while one is in flight. The
    // loading state is emitted before the first await, so a second tap that
    // arrives straight after the first is still caught here.
    if (state.placeOrderStatus.isLoading) {
      _logger.w('$kTag Already placing an order, ignoring request');
      return;
    }
    // Emit state with loading status
    emit(
      state.copyWith(
        placeOrderStatus: PlaceOrderStatus.loading,
        placeOrderFailure: const Optional.set(null),
        orderId: const Optional.set(null),
      ),
    );
    try {
      _logger.i('$kTag Placing order...');
      final Map<String, dynamic> response = await _orderService.placeOrder(
        placeOrderRequest: event.placeOrderRequest,
      );
      final int? orderId = response['id'] as int?;
      _logger.i('$kTag Order placed successfully, id: $orderId');
      // Emit state with success status and the order ID
      emit(
        state.copyWith(
          placeOrderStatus: PlaceOrderStatus.success,
          placeOrderFailure: const Optional.set(null),
          orderId: Optional.set(orderId),
        ),
      );
    } catch (e) {
      _logger.e('$kTag Place order failed: $e');
      // Errors that aren't a Failure have nothing to show, so the UI falls
      // back to a generic message.
      final Failure? failure = e is Failure ? e : null;
      // Emit state with failure status and failure
      emit(
        state.copyWith(
          placeOrderStatus: PlaceOrderStatus.failure,
          placeOrderFailure: Optional.set(failure),
        ),
      );
    }
  }

  void _mapResetCheckoutEventToState(
    ResetCheckout event,
    Emitter<CheckoutState> emit,
  ) {
    const String kTag = '$_kTag[ResetCheckout]';
    // Resetting mid-request would drop the double-submit guard.
    if (state.placeOrderStatus.isLoading) {
      _logger.w('$kTag Order in flight, ignoring reset');
      return;
    }
    _logger.d('$kTag Resetting checkout');
    emit(const CheckoutState());
  }
}
