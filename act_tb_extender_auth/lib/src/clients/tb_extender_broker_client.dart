// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_tb_extender_auth/src/models/broker_claim_result.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_response.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_result.dart';
import 'package:act_tb_extender_auth/src/types/broker_auth_error.dart';
import 'package:http/http.dart' as http;

/// A small REST client for the auth broker of tb-extender.
///
/// It offers [login], which exchanges a Keycloak access token for a pair of ThingsBoard tokens,
/// [deleteAccount], which erases the account behind such a token, [acceptTerms], which writes on
/// it the version of the terms the user accepted, [claimDevice], which assigns a device to the
/// customer of the caller, and [releaseDevice], which hands a device back.
/// Every call holds no state and is idempotent; therefore, they can safely be issued again
/// whenever the ThingsBoard tokens are lost or refused.
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

  /// This is the relative path of the devices endpoints, the serial and the action follow it
  static const _devicesPath = "/api/v1/devices";

  /// This is the key the claim secret is sent to the claim and release endpoints under
  static const _secretKey = "secret";

  /// This is the key the id of the claimed device is read from
  static const _deviceIdKey = "deviceId";

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

  /// Assign the device named [serial] to the customer of the caller.
  ///
  /// Issues `POST <brokerUrl>/api/v1/devices/<serial>/claim` with an
  /// `Authorization: Bearer <token>` header and the claim [secret] the application pushed to the
  /// device as a JSON body. The broker checks it against the secret the device published, which
  /// is the proof the caller holds the device, and hands over a device held by another customer
  /// on its own: the caller has nothing more to do.
  ///
  /// Return a [BrokerClaimSuccess] naming the device on a HTTP 200, or a [BrokerClaimFailure]
  /// carrying the mapped [BrokerAuthError] otherwise — [BrokerAuthError.claimRefused] for an
  /// unknown serial or a wrong, missing or too old secret — a transport error being read as
  /// [BrokerAuthError.network].
  Future<BrokerClaimResult> claimDevice(
    String keycloakAccessToken, {
    required String serial,
    required String secret,
  }) async {
    final uri = _buildUri("$_devicesPath/${Uri.encodeComponent(serial)}/claim");
    if (uri == null) {
      _logsHelper.e("The base URL of the broker isn't configured, can't claim a device");
      return const BrokerClaimFailure(BrokerAuthError.unknown);
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {..._headers(keycloakAccessToken), "Content-Type": "application/json"},
            body: jsonEncode({_secretKey: secret}),
          )
          .timeout(_requestTimeout);
    } catch (error) {
      _logsHelper.w("A transport error occurred when calling the claim endpoint of the broker: "
          "$error");
      return const BrokerClaimFailure(BrokerAuthError.network);
    }

    final json = _tryDecodeBody(response);

    if (response.statusCode == 200) {
      final deviceId = _readString(json, _deviceIdKey);
      if (deviceId == null) {
        _logsHelper.w("The broker answered a 200 to the claim without naming the device");
        return const BrokerClaimFailure(BrokerAuthError.unknown);
      }

      return BrokerClaimSuccess(deviceId: deviceId);
    }

    final code = _readString(json, _errorKey);
    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The device claim failed with the status ${response.statusCode} "
        "(code: $code, error: $error)");

    return BrokerClaimFailure(error);
  }

  /// Release the device named [serial] from the customer which holds it.
  ///
  /// Issues `POST <brokerUrl>/api/v1/devices/<serial>/release` with an
  /// `Authorization: Bearer <token>` header. [secret] is the claim secret the application pushed
  /// to the device, sent as a JSON body when given: the broker needs it to release a device of
  /// another customer, and ignores it for a device of the customer of the caller.
  ///
  /// Return null on a HTTP 204, the device being released or already free, or the mapped
  /// [BrokerAuthError] otherwise — [BrokerAuthError.releaseRefused] for an unknown serial or a
  /// wrong secret — a transport error being read as [BrokerAuthError.network].
  Future<BrokerAuthError?> releaseDevice(
    String keycloakAccessToken, {
    required String serial,
    String? secret,
  }) async {
    final uri = _buildUri("$_devicesPath/${Uri.encodeComponent(serial)}/release");
    if (uri == null) {
      _logsHelper.e("The base URL of the broker isn't configured, can't release a device");
      return BrokerAuthError.unknown;
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              ..._headers(keycloakAccessToken),
              if (secret != null) "Content-Type": "application/json",
            },
            body: (secret == null) ? null : jsonEncode({_secretKey: secret}),
          )
          .timeout(_requestTimeout);
    } catch (error) {
      _logsHelper.w("A transport error occurred when calling the release endpoint of the broker: "
          "$error");
      return BrokerAuthError.network;
    }

    if (response.statusCode == 204) {
      return null;
    }

    final code = _readString(_tryDecodeBody(response), _errorKey);
    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The device release failed with the status ${response.statusCode} "
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
