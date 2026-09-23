// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_response.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_result.dart';
import 'package:act_tb_extender_auth/src/types/broker_auth_error.dart';
import 'package:http/http.dart' as http;

/// A small REST client for the auth broker of tb-extender.
///
/// It offers [login], which exchanges a Keycloak access token for a pair of ThingsBoard tokens,
/// [deleteAccount], which erases the account behind such a token, and [acceptTerms], which writes
/// on it the version of the terms the user accepted. Every call holds no state and is idempotent;
/// therefore, they can safely be issued again whenever the ThingsBoard tokens are lost or
/// refused.
///
/// The base URL is read through a getter rather than given once: the configuration of an
/// application is loaded after its managers are built, so the URL is only there by the time the
/// first call is made.
///
/// A call the broker doesn't answer within the timeout the client was built with is read as a
/// transport failure.
class TbExtenderBrokerClient {
  /// This is the logs category linked to the broker client
  static const _logsCategory = "tbExtenderBroker";

  /// This is the relative path of the login endpoint
  static const _loginPath = "/api/v1/auth/login";

  /// This is the relative path of the account deletion endpoint
  static const _accountPath = "/api/v1/account";

  /// This is the relative path of the terms acceptance endpoint
  static const _termsAcceptPath = "/api/v1/terms/accept";

  /// This is the key the accepted version is sent to the terms endpoint under
  static const _versionKey = "version";

  /// This is the key the error code of a broker error payload is read from
  static const _errorKey = "error";

  /// This is the key the error message of a broker error payload is read from
  static const _messageKey = "message";

  /// The time the broker is given to answer a call, after which the call is read as a transport
  /// failure
  static const defaultRequestTimeout = Duration(seconds: 15);

  /// The HTTP client the requests are issued with
  final http.Client _httpClient;

  /// The getter of the base URL of the broker
  final String? Function() _baseUrlGetter;

  /// The logs helper linked to the client
  final LogsHelper _logsHelper;

  /// The time the broker is given to answer each call
  final Duration _requestTimeout;

  /// Class constructor
  ///
  /// [baseUrlGetter] answers the base URL of the broker, and is called at each request so that the
  /// configuration of an application can be loaded after the client is built. [httpClient]
  /// defaults to a fresh [http.Client], and [requestTimeout] is the time the broker is given to
  /// answer each call.
  TbExtenderBrokerClient({
    required String? Function() baseUrlGetter,
    http.Client? httpClient,
    Duration requestTimeout = defaultRequestTimeout,
  }) : _baseUrlGetter = baseUrlGetter,
       _httpClient = httpClient ?? http.Client(),
       _requestTimeout = requestTimeout,
       _logsHelper = LogsHelper(category: _logsCategory);

  /// Exchange the given [keycloakAccessToken] for a pair of ThingsBoard tokens.
  ///
  /// Issues `POST <brokerUrl>/api/v1/auth/login` with an `Authorization: Bearer <token>` header
  /// and no body.
  ///
  /// Return a [BrokerLoginSuccess] on a HTTP 200, or a [BrokerLoginFailure] carrying the mapped
  /// [BrokerAuthError] otherwise, a transport error being read as [BrokerAuthError.network].
  Future<BrokerLoginResult> login(String keycloakAccessToken) async {
    final uri = _buildUri(_loginPath);
    if (uri == null) {
      _logsHelper.e("The base URL of the broker isn't configured, can't exchange the Keycloak "
          "token");
      return const BrokerLoginFailure(BrokerAuthError.unknown);
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(uri, headers: _headers(keycloakAccessToken))
          .timeout(_requestTimeout);
    } catch (error) {
      _logsHelper.w("A transport error occurred when calling the login endpoint of the broker: "
          "$error");
      return const BrokerLoginFailure(BrokerAuthError.network);
    }

    if (response.statusCode == 200) {
      return _parseSuccess(response);
    }

    return _parseError(response);
  }

  /// Erase the account behind the given [keycloakAccessToken], on the ThingsBoard side as well as
  /// on the Keycloak one.
  ///
  /// Issues `DELETE <brokerUrl>/api/v1/account` with an `Authorization: Bearer <token>` header and
  /// no body.
  ///
  /// Return null on a HTTP 204, the account being gone, or the mapped [BrokerAuthError] otherwise,
  /// a transport error being read as [BrokerAuthError.network].
  Future<BrokerAuthError?> deleteAccount(String keycloakAccessToken) async {
    final uri = _buildUri(_accountPath);
    if (uri == null) {
      _logsHelper.e("The base URL of the broker isn't configured, can't delete the account");
      return BrokerAuthError.unknown;
    }

    http.Response response;
    try {
      response = await _httpClient
          .delete(uri, headers: _headers(keycloakAccessToken))
          .timeout(_requestTimeout);
    } catch (error) {
      _logsHelper.w("A transport error occurred when calling the account endpoint of the broker: "
          "$error");
      return BrokerAuthError.network;
    }

    if (response.statusCode == 204) {
      return null;
    }

    final code = _readString(_tryDecodeBody(response), _errorKey);
    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The account deletion failed with the status ${response.statusCode} "
        "(code: $code, error: $error)");

    return error;
  }

  /// Record on the account that the user accepted the [version] of the terms.
  ///
  /// Issues `POST <brokerUrl>/api/v1/terms/accept` with an `Authorization: Bearer <token>` header
  /// and the version as a JSON body.
  ///
  /// Return null when the broker recorded it, on a HTTP 204, or the mapped [BrokerAuthError]
  /// otherwise, a transport error being read as [BrokerAuthError.network].
  Future<BrokerAuthError?> acceptTerms(
    String keycloakAccessToken, {
    required String version,
  }) async {
    final uri = _buildUri(_termsAcceptPath);
    if (uri == null) {
      _logsHelper.e("The base URL of the broker isn't configured, can't record the terms");
      return BrokerAuthError.unknown;
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {..._headers(keycloakAccessToken), "Content-Type": "application/json"},
            body: jsonEncode({_versionKey: version}),
          )
          .timeout(_requestTimeout);
    } catch (error) {
      _logsHelper.w("A transport error occurred when calling the terms endpoint of the broker: "
          "$error");
      return BrokerAuthError.network;
    }

    if (response.statusCode == 204) {
      return null;
    }

    final code = _readString(_tryDecodeBody(response), _errorKey);
    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The terms acceptance failed with the status ${response.statusCode} "
        "(code: $code, error: $error)");

    return error;
  }

  /// Close the HTTP client underneath and release its resources.
  void close() => _httpClient.close();

  /// Build the URI of the [path] endpoint out of the base URL the getter answers.
  ///
  /// Return null when no base URL was configured, a single trailing slash on it being removed so
  /// that the concatenation stays clean.
  Uri? _buildUri(String path) {
    final baseUrl = _baseUrlGetter();
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }

    final trimmed = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    return Uri.parse("$trimmed$path");
  }

  /// Build the headers every call of the broker carries, which name the [keycloakAccessToken] the
  /// broker authenticates the caller with.
  Map<String, String> _headers(String keycloakAccessToken) => {
    "Authorization": "Bearer $keycloakAccessToken",
    "Accept": "application/json",
  };

  /// Parse a HTTP 200 [response] of the broker into a [BrokerLoginSuccess], or into the failure of
  /// a malformed body.
  BrokerLoginResult _parseSuccess(http.Response response) {
    final json = _tryDecodeBody(response);
    if (json == null) {
      _logsHelper.w("The broker answered a 200 with a body which isn't a JSON object");
      return const BrokerLoginFailure(BrokerAuthError.unknown, statusCode: 200);
    }

    final parsed = BrokerLoginResponse.fromJson(json);
    if (parsed == null) {
      _logsHelper.w("The broker answered a 200 but its payload couldn't be parsed");
      return const BrokerLoginFailure(BrokerAuthError.unknown, statusCode: 200);
    }

    return BrokerLoginSuccess(parsed);
  }

  /// Parse a [response] of the broker which isn't a 200 into a typed [BrokerLoginFailure].
  BrokerLoginResult _parseError(http.Response response) {
    final json = _tryDecodeBody(response);
    final code = _readString(json, _errorKey);
    final message = _readString(json, _messageKey);

    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The broker login failed with the status ${response.statusCode} (code: $code, "
        "error: $error)");

    return BrokerLoginFailure(error, message: message, statusCode: response.statusCode);
  }

  /// Read the [key] of the [json] the broker answered, when it holds a string.
  String? _readString(Map<String, dynamic>? json, String key) {
    final value = json?[key];

    return (value is String) ? value : null;
  }

  /// Try to decode the body of the [response] as a JSON object, returning null on any failure.
  Map<String, dynamic>? _tryDecodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(response.body);
      return (decoded is Map<String, dynamic>) ? decoded : null;
    } catch (error) {
      _logsHelper.d("The body of the broker isn't a valid JSON: $error");
      return null;
    }
  }
}
