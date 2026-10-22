part of 'checkout_bloc.dart';

enum PlaceOrderStatus { initial, loading, success, failure }

extension PlaceOrderStatusX on PlaceOrderStatus {
  bool get isInitial => this == PlaceOrderStatus.initial;
  bool get isLoading => this == PlaceOrderStatus.loading;
  bool get isSuccess => this == PlaceOrderStatus.success;
  bool get isFailure => this == PlaceOrderStatus.failure;
}

class CheckoutState extends Equatable {
  final PlaceOrderStatus placeOrderStatus;
  final Failure? placeOrderFailure;
  // The order ID from the API, shown in the confirmation.
  final int? orderId;

  const CheckoutState({
    this.placeOrderStatus = PlaceOrderStatus.initial,
    this.placeOrderFailure,
    this.orderId,
  });

  @override
  List<Object?> get props => [placeOrderStatus, placeOrderFailure, orderId];

  CheckoutState copyWith({
    PlaceOrderStatus? placeOrderStatus,
    Optional<Failure> placeOrderFailure = const Optional(),
    Optional<int> orderId = const Optional(),
  }) {
    return CheckoutState(
      placeOrderStatus: placeOrderStatus ?? this.placeOrderStatus,
      placeOrderFailure: resolveOptional(
        placeOrderFailure,
        this.placeOrderFailure,
      ),
      orderId: resolveOptional(orderId, this.orderId),
    );
  }
}
