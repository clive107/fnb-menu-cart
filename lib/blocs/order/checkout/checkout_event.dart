part of 'checkout_bloc.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class PlaceOrder extends CheckoutEvent {
  final PlaceOrderRequest placeOrderRequest;

  const PlaceOrder({required this.placeOrderRequest});

  @override
  List<Object?> get props => [placeOrderRequest];
}

/// Returns to the initial state, e.g. after the result has been shown.
class ResetCheckout extends CheckoutEvent {
  const ResetCheckout();
}
