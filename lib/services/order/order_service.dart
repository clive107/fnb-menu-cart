import 'dart:io' show HttpStatus;

import 'package:equatable/equatable.dart';
import 'package:fnb_menu_cart/configs/app/constants.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/services/app/api_client.dart';

class OrderService {
  final ApiClient _apiClient;
  final bool _forceFailure;

  OrderService({
    required ApiClient apiClient,
    bool forceFailure = kForceCheckoutFailure,
  }) : _apiClient = apiClient,
       _forceFailure = forceFailure;

  Future<Map<String, dynamic>> placeOrder({
    required PlaceOrderRequest placeOrderRequest,
  }) async {
    if (_forceFailure) {
      // Wait like a slow server first, so the in-flight state is visible.
      await Future<void>.delayed(const Duration(seconds: 1));
      throw const Failure(statusCode: HttpStatus.serviceUnavailable);
    }
    return _apiClient.jsonPost(
      kPlaceOrderPath,
      body: {
        'userId': kDemoUserId,
        'products': [
          for (final MapEntry<int, int> entry
              in placeOrderRequest.quantityByItemId.entries)
            {'id': entry.key, 'quantity': entry.value},
        ],
      },
    );
  }
}

class PlaceOrderRequest extends Equatable {
  /// Quantity ordered per menu item ID.
  final Map<int, int> quantityByItemId;

  const PlaceOrderRequest({required this.quantityByItemId});

  @override
  List<Object?> get props => [quantityByItemId];
}
