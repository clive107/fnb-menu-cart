import 'dart:io' show HttpStatus;

import 'package:flutter_test/flutter_test.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:fnb_menu_cart/utils/app/error_handling/get_failure_message.dart';

void main() {
  group('getFailureMessage -', () {
    test('returns the unknown error message when failure is null', () {
      expect(getFailureMessage(), kUnknownErrorMessage);
    });

    test('returns the API message when the failure has one', () {
      const Failure failure = Failure(
        statusCode: HttpStatus.notFound,
        errorCode: kTimeout,
        message: "Product with id '1' not found",
      );

      expect(
        getFailureMessage(failure: failure),
        "Product with id '1' not found",
      );
    });

    /* Section - Custom error codes */
    test('returns the client exception message for ClientExceptionFailure', () {
      expect(
        getFailureMessage(failure: const ClientExceptionFailure()),
        kClientExceptionMessage,
      );
    });

    test('returns the bad format message for the bad format error code', () {
      const Failure failure = Failure(
        statusCode: HttpStatus.ok,
        errorCode: kBadFormatFailure,
      );

      expect(getFailureMessage(failure: failure), kBadFormatMessage);
    });

    test('returns the timeout message for TimeoutFailure', () {
      expect(
        getFailureMessage(failure: const TimeoutFailure()),
        kTimeoutMessage,
      );
    });

    /* Section - HTTP status codes */
    test('returns the bad request message for 400', () {
      expect(
        getFailureMessage(
          failure: const Failure(statusCode: HttpStatus.badRequest),
        ),
        kBadRequestMessage,
      );
    });

    test('returns the not found message for 404', () {
      expect(
        getFailureMessage(
          failure: const Failure(statusCode: HttpStatus.notFound),
        ),
        kNotFoundMessage,
      );
    });

    test('returns the timeout message for 408 and 504', () {
      for (final int statusCode in [
        HttpStatus.requestTimeout,
        HttpStatus.gatewayTimeout,
      ]) {
        expect(
          getFailureMessage(failure: Failure(statusCode: statusCode)),
          kTimeoutMessage,
        );
      }
    });

    test('returns the server error message for 500, 502 and 503', () {
      for (final int statusCode in [
        HttpStatus.internalServerError,
        HttpStatus.badGateway,
        HttpStatus.serviceUnavailable,
      ]) {
        expect(
          getFailureMessage(failure: Failure(statusCode: statusCode)),
          kServerErrorMessage,
        );
      }
    });

    test('returns the unknown error message for any other status code', () {
      expect(
        getFailureMessage(
          failure: const Failure(statusCode: HttpStatus.forbidden),
        ),
        kUnknownErrorMessage,
      );
    });
  });
}
