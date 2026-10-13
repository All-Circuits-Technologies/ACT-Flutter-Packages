// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_tb_extender_client/src/models/broker_claim_result.dart';
import 'package:act_tb_extender_client/src/models/broker_login_response.dart';
import 'package:act_tb_extender_client/src/models/broker_login_result.dart';
import 'package:act_tb_extender_client/src/types/broker_auth_error.dart';

/// A small REST client for the auth broker of tb-extender.
///
/// It offers [login], which exchanges an access token of the identity provider for a pair of
/// ThingsBoard tokens, [deleteAccount], which erases the account behind such a token,
/// [acceptTerms], which writes on it the version of the terms the user accepted, [claimDevice],
/// which assigns a device to the customer of the caller, and [releaseDevice], which hands a device
/// back.
/// Every call holds no state and is idempotent; therefore, they can safely be issued again
/// whenever the ThingsBoard tokens are lost or refused.
///
/// The requests go through [AbsHttpClientManager], without its login: the broker authenticates
/// each call by the token of the identity provider it carries. The client has to be initialized
/// before its first call, which is when the base URL of the broker is read; the configuration of
/// an application, loaded after its managers are built, is there by then.
///
/// A call the broker doesn't answer within the timeout the client was built with is read as a
/// transport failure.
class TbExtenderBrokerClient extends AbsHttpClientManager<AbsHttpClientLogin?> {
  /// This is the logs category linked to the broker client
  static const _logsCategory = "tbExtenderBroker";

  /// This is the relative path of the login endpoint
  static const _loginPath = "/api/v1/auth/login";

  /// This is the relative path of the account deletion endpoint
  static const _accountPath = "/api/v1/account";

  /// This is the relative path of the terms acceptance endpoint
  static const _termsAcceptPath = "/api/v1/terms/accept";

  /// This is the relative path of the devices endpoints, the serial and the action follow it
  ///
  /// The requester encodes each segment of the path, but splits it on the slashes first: a serial
  /// can't hold one.
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

  /// The getter of the base URL of the broker
  final String? Function() _baseUrlGetter;

  /// The logs helper linked to the client
  final LogsHelper _logsHelper;

  /// The time the broker is given to answer each call
  final Duration _requestTimeout;

  /// Class constructor
  ///
  /// [baseUrlGetter] answers the base URL of the broker, and is called when the client is
  /// initialized so that the configuration of an application can be loaded after the client is
  /// built. [requestTimeout] is the time the broker is given to answer each call.
  TbExtenderBrokerClient({
    required String? Function() baseUrlGetter,
    Duration requestTimeout = defaultRequestTimeout,
  }) : _baseUrlGetter = baseUrlGetter,
       _requestTimeout = requestTimeout,
       _logsHelper = LogsHelper(category: _logsCategory);

  /// Exchange the given [idpAccessToken] for a pair of ThingsBoard tokens.
  ///
  /// Issues `POST <brokerUrl>/api/v1/auth/login` with an `Authorization: Bearer <token>` header
  /// and no body.
  ///
  /// Return a [BrokerLoginSuccess] on a HTTP 200, or a [BrokerLoginFailure] carrying the mapped
  /// [BrokerAuthError] otherwise, a transport error being read as [BrokerAuthError.network].
  Future<BrokerLoginResult> login(String idpAccessToken) async {
    final answer = await executeRequestWithJsonObjRespBody<BrokerLoginResponse>(
      requestParam: _requestParam(_loginPath, idpAccessToken),
      parseRespBody: BrokerLoginResponse.fromJson,
    );

    final parsed = answer.castedBody;
    if (answer.status == RequestStatus.success && parsed != null) {
      return BrokerLoginSuccess(parsed);
    }

    final failure = _readFailure(answer, "login");

    return BrokerLoginFailure(
      failure.error,
      message: failure.message,
      statusCode: answer.response?.statusCode,
    );
  }

  /// Erase the account behind the given [idpAccessToken], on the ThingsBoard side as well as
  /// on the side of the identity provider.
  ///
  /// Issues `DELETE <brokerUrl>/api/v1/account` with an `Authorization: Bearer <token>` header and
  /// no body.
  ///
  /// Return null on a HTTP 204, the account being gone, or the mapped [BrokerAuthError] otherwise,
  /// a transport error being read as [BrokerAuthError.network].
  Future<BrokerAuthError?> deleteAccount(String idpAccessToken) => _requestWithoutAnswer(
    _requestParam(_accountPath, idpAccessToken, httpMethod: HttpMethods.delete),
    "account deletion",
  );

  /// Record on the account that the user accepted the [version] of the terms.
  ///
  /// Issues `POST <brokerUrl>/api/v1/terms/accept` with an `Authorization: Bearer <token>` header
  /// and the version as a JSON body.
  ///
  /// Return null when the broker recorded it, on a HTTP 204, or the mapped [BrokerAuthError]
  /// otherwise, a transport error being read as [BrokerAuthError.network].
  Future<BrokerAuthError?> acceptTerms(
    String idpAccessToken, {
    required String version,
  }) => _requestWithoutAnswer(
    _requestParam(_termsAcceptPath, idpAccessToken, body: {_versionKey: version}),
    "terms acceptance",
  );

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
    String idpAccessToken, {
    required String serial,
    required String secret,
  }) async {
    final answer = await executeRequestWithJsonObjRespBody<String>(
      requestParam: _requestParam(
        "$_devicesPath/$serial/claim",
        idpAccessToken,
        body: {_secretKey: secret},
      ),
      parseRespBody: (json) => _readString(json, _deviceIdKey),
    );

    final deviceId = answer.castedBody;
    if (answer.status == RequestStatus.success && deviceId != null) {
      return BrokerClaimSuccess(deviceId: deviceId);
    }

    return BrokerClaimFailure(_readFailure(answer, "device claim").error);
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
    String idpAccessToken, {
    required String serial,
    String? secret,
  }) => _requestWithoutAnswer(
    _requestParam(
      "$_devicesPath/$serial/release",
      idpAccessToken,
      body: (secret == null) ? null : {_secretKey: secret},
    ),
    "device release",
  );

  /// {@macro act_http_client_manager.AbsServerReqManager.getRequesterConfig}
  ///
  /// The base URL of the broker is read here, and its absence makes the initialization fail.
  @override
  Future<RequesterConfig> getRequesterConfig() async {
    final baseUrl = _baseUrlGetter();
    final uri = (baseUrl == null) ? null : Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) {
      const configName = "tb-extender broker base URL";
      _logsHelper.e("The configuration value: $configName, is missing or isn't a valid URL");
      throw ActMissingConfigException(configName);
    }

    return RequesterConfig(
      loggerEnabled: true,
      loggerCategory: _logsCategory,
      defaultTimeout: _requestTimeout,
      defaultServerInfo: RequesterServerUrlConfig(
        isUsingSsl: uri.isScheme("https"),
        hostname: uri.host,
        port: uri.hasPort ? uri.port : null,
        baseUrl: uri.path,
      ),
    );
  }

  /// {@macro act_http_client_manager.AbsServerReqManager.createServerLogin}
  ///
  /// The broker has no login of its own: each call carries the token of the identity provider.
  @override
  Future<AbsHttpClientLogin?> createServerLogin({
    required ServerRequester serverRequester,
    required LogsHelper parentLogsHelper,
  }) async => null;

  /// Build the request of the [route] endpoint, which carries the [idpAccessToken] the broker
  /// authenticates the caller with and, when given, the [body] as JSON.
  RequestParam _requestParam(
    String route,
    String idpAccessToken, {
    HttpMethods httpMethod = HttpMethods.post,
    Map<String, dynamic>? body,
  }) => RequestParam(
    httpMethod: httpMethod,
    relativeRoute: route,
    headers: {"Authorization": "Bearer $idpAccessToken", "Accept": "application/json"},
    body: body,
  );

  /// Issue the [requestParam] of an endpoint which answers no body, the [callName] naming it in
  /// the logs.
  ///
  /// Return null on a success, or the mapped [BrokerAuthError] otherwise.
  Future<BrokerAuthError?> _requestWithoutAnswer(RequestParam requestParam, String callName) async {
    final answer = await executeRequest<Object, Object>(requestParam: requestParam);
    if (answer.status == RequestStatus.success) {
      return null;
    }

    return _readFailure(answer, callName).error;
  }

  /// Read the error and the message of the broker [answer] to the [callName] call which didn't
  /// succeed.
  ///
  /// A call which got no answer at all, because of a transport error or a timeout, is read as
  /// [BrokerAuthError.network].
  ({BrokerAuthError error, String? message}) _readFailure(
    RequestResponse<Object?> answer,
    String callName,
  ) {
    final response = answer.response;
    if (response == null) {
      _logsHelper.w("The $callName got no answer from the broker (${answer.status})");
      return (error: BrokerAuthError.network, message: null);
    }

    final json = _tryDecodeBody(response);
    final code = _readString(json, _errorKey);
    final error = BrokerAuthError.fromCode(code);
    _logsHelper.w("The $callName failed with the status ${response.statusCode} (code: $code, "
        "error: $error)");

    return (error: error, message: _readString(json, _messageKey));
  }

  /// Read the [key] of the [json] the broker answered, when it holds a string.
  String? _readString(Map<String, dynamic>? json, String key) {
    final value = json?[key];

    return (value is String) ? value : null;
  }

  /// Try to decode the body of the [response] as a JSON object, returning null on any failure.
  Map<String, dynamic>? _tryDecodeBody(Response response) {
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
