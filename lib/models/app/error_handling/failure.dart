import 'dart:io' show HttpStatus;

import 'package:equatable/equatable.dart';

/* Section - List of custom error codes */
const String kClientException = 'client_exception';
const String kBadFormatFailure = 'bad_format';
const String kTimeout = 'timeout';

class Failure extends Equatable {
  final int statusCode;
  final String? errorCode;
  final String? message;
  final Map<String, dynamic>? data;

  const Failure({
    required this.statusCode,
    this.errorCode,
    this.message,
    this.data,
  });

  @override
  // data is intentionally excluded — Map equality is fragile and data is
  // an opaque payload, not an identity discriminator for failure types.
  List<Object?> get props => [statusCode, errorCode, message];

  Failure copyWith({
    int? statusCode,
    String? errorCode,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return Failure(
      statusCode: statusCode ?? this.statusCode,
      errorCode: errorCode ?? this.errorCode,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

/// Raised when the request never reached the server or the connection broke,
/// for example no internet. No HTTP response arrived, so [statusCode] is a
/// placeholder; [errorCode] ([kClientException]) is the real discriminator.
class ClientExceptionFailure extends Failure {
  const ClientExceptionFailure({super.message, super.data})
    : super(statusCode: HttpStatus.badRequest, errorCode: kClientException);

  @override
  ClientExceptionFailure copyWith({
    int? statusCode, // ignored — statusCode is an invariant of this type
    String? errorCode, // ignored — errorCode is an invariant of this type
    String? message,
    Map<String, dynamic>? data,
  }) {
    return ClientExceptionFailure(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

/// Raised when a request exceeds the client-side timeout and is aborted before
/// any response is received. This is distinct from a server-returned 408/504 —
/// here no HTTP response ever arrived. [errorCode] ([kTimeout]) is the real
/// discriminator; [statusCode] reuses HttpStatus.requestTimeout as a
/// placeholder.
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message, super.data})
    : super(statusCode: HttpStatus.requestTimeout, errorCode: kTimeout);

  @override
  TimeoutFailure copyWith({
    int? statusCode, // ignored — statusCode is an invariant of this type
    String? errorCode, // ignored — errorCode is an invariant of this type
    String? message,
    Map<String, dynamic>? data,
  }) {
    return TimeoutFailure(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}
