import 'dart:async' show TimeoutException;
import 'dart:convert';

import 'package:fnb_menu_cart/configs/app/constants.dart';
import 'package:fnb_menu_cart/models/app/error_handling/failure.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Sends JSON requests and turns every error into a [Failure], so blocs only
/// need to catch [Failure].
class ApiClient {
  static const String _kTag = '[ApiClient]';

  final Logger _logger;
  final http.Client _httpClient;
  final String _apiBaseUrl;
  final Duration _defaultTimeout;

  ApiClient({
    required Logger logger,
    required http.Client httpClient,
    String apiBaseUrl = kApiBaseUrl,
    Duration defaultTimeout = kApiTimeout,
  }) : _logger = logger,
       _httpClient = httpClient,
       _apiBaseUrl = apiBaseUrl,
       _defaultTimeout = defaultTimeout;

  Future<Map<String, dynamic>> jsonGet(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) {
    return _makeRequest('GET', path, query: query, timeout: timeout);
  }

  Future<Map<String, dynamic>> jsonPost(
    String path, {
    Object? body,
    Duration? timeout,
  }) {
    return _makeRequest('POST', path, body: body, timeout: timeout);
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Duration? timeout,
  }) async {
    final Uri uri = Uri.parse(
      '$_apiBaseUrl/$path',
    ).replace(queryParameters: query);
    final Duration effectiveTimeout = timeout ?? _defaultTimeout;
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    _logger.i('$_kTag [$method] $uri');

    final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(effectiveTimeout);
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(effectiveTimeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      _logger.e(
        '$_kTag [$method] timed out after ${effectiveTimeout.inSeconds}s - $uri',
      );
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      // No response arrived, for example no internet. The IO client also
      // wraps SocketException in ClientException.
      _logger.e('$_kTag [$method] ClientException - $uri: $e');
      throw const ClientExceptionFailure();
    }

    return _handleResponse(uri, response);
  }

  Map<String, dynamic> _handleResponse(Uri uri, http.Response response) {
    _logger.i('$_kTag $uri, status code: ${response.statusCode}');
    final Object? body = _tryDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        _logger.d('$_kTag Response body: $body');
        return body;
      }
      // A success status with a body that isn't a JSON object.
      _logger.e('$_kTag Unexpected response body: ${response.body}');
      throw Failure(
        statusCode: response.statusCode,
        errorCode: kBadFormatFailure,
      );
    }

    // Error responses may be HTML (e.g. a gateway error page), so the message
    // is optional.
    final String? message =
        body is Map<String, dynamic> && body['message'] is String
        ? body['message'] as String
        : null;
    _logger.e('$_kTag Error response: ${response.body}');
    throw Failure(statusCode: response.statusCode, message: message);
  }

  /// Returns the decoded JSON, or null when the body is empty or not JSON.
  Object? _tryDecode(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
