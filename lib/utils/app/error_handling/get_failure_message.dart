import 'dart:io' show HttpStatus;

import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';

/* Section - Constants for failure messages */
const String kUnknownErrorMessage = 'Something went wrong. Please try again.';
const String kClientExceptionMessage =
    "Can't connect. Check your internet connection and try again.";
const String kBadFormatMessage =
    'We received an unexpected response. Please try again.';
const String kTimeoutMessage = 'The request took too long. Please try again.';
const String kBadRequestMessage = "The request couldn't be processed.";
const String kNotFoundMessage = "We couldn't find what you were looking for.";
const String kServerErrorMessage =
    'The service is unavailable right now. Please try again later.';

/// Returns a message to show the user for [failure].
String getFailureMessage({Failure? failure}) {
  // If the failure is null, return an unknown error message
  if (failure == null) {
    return kUnknownErrorMessage;
  }

  // If the failure contains a message (from the API), return the message
  if (failure.message != null) {
    return failure.message!;
  }

  /* Handle custom error codes */
  if (failure.errorCode == kClientException) {
    return kClientExceptionMessage;
  } else if (failure.errorCode == kBadFormatFailure) {
    return kBadFormatMessage;
  } else if (failure.errorCode == kTimeout) {
    return kTimeoutMessage;
  }

  /* Handle HTTP status codes */
  if (failure.statusCode == HttpStatus.badRequest) {
    return kBadRequestMessage;
  } else if (failure.statusCode == HttpStatus.notFound) {
    return kNotFoundMessage;
  } else if ([
    HttpStatus.requestTimeout,
    HttpStatus.gatewayTimeout,
  ].contains(failure.statusCode)) {
    return kTimeoutMessage;
  } else if ([
    HttpStatus.internalServerError,
    HttpStatus.badGateway,
    HttpStatus.serviceUnavailable,
  ].contains(failure.statusCode)) {
    return kServerErrorMessage;
  }
  return kUnknownErrorMessage;
}
