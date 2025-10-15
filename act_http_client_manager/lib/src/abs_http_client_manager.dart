// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/src/abs_http_client_login.dart';
import 'package:act_http_client_manager/src/models/request_param.dart';
import 'package:act_http_client_manager/src/models/request_response.dart';
import 'package:act_http_client_manager/src/models/requester_config.dart';
import 'package:act_http_client_manager/src/models/server_urls.dart';
import 'package:act_http_client_manager/src/server_requester.dart';
import 'package:act_http_client_manager/src/types/login_fail_policy.dart';
import 'package:act_http_core/src/types/mime_types.dart';
import 'package:act_http_client_manager/src/types/request_status.dart';
import 'package:act_http_client_manager/src/utilities/url_format_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

/// Builder of the [AbsHttpClientManager] manager
abstract class AbsHttpClientBuilder<T extends AbsHttpClientManager> extends AbsManagerBuilder<T> {
  /// Class constructor
  const AbsHttpClientBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This class defines a manager useful to request a third server.
///
/// A login process may be added to it, if the third server needs a login to execute requests
abstract class AbsHttpClientManager<T extends AbsHttpClientLogin?> extends AbsWithLifeCycle {
  /// {@template act_http_client_manager.AbsServerReqManager.serverUrls}
  /// This contains the base of all URL to request the server: the default one and the overrided
  /// URLs depending of the relative routes
  /// The server URLs are formatted liked that: http(s)://{hostname}:{port}/{baseUrl}
  /// {@endtemplate}
  late final ServerUrls _serverUrls;

  /// Getter of the [_serverUrls]
  ///
  /// {@macro act_http_client_manager.AbsServerReqManager.serverUrls}
  ServerUrls get serverUrls => _serverUrls;

  /// This is the logs helper linked to the request manager
  late final LogsHelper _logsHelper;

  /// {@template act_http_client_manager.AbsServerReqManager.absServerLogin}
  /// This is the server login to use in order to logIn into the server, if undefined, there is no
  /// authentication to the server
  /// {@endtemplate}
  late final T _absServerLogin;

  /// {@macro act_http_client_manager.AbsServerReqManager.absServerLogin}
  T get absServerLogin => _absServerLogin;

  /// This is the server request linked to requester manager, it allows to request the third server
  late final ServerRequester _serverRequester;

  /// Call this method to initialize the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    final config = await getRequesterConfig();

    if (config.parentLogsHelper == null) {
      _logsHelper = LogsHelper(
        logsManager: globalGetIt().get<LoggerManager>(),
        logsCategory: config.loggerCategory,
        enableLog: config.loggerEnabled,
      );
    } else {
      _logsHelper = config.parentLogsHelper!.createASubLogsHelper(config.loggerCategory);
    }

    final urlsByRelRoute = <String, Uri>{};

    if (config.serverInfoByUrl != null) {
      for (final infoByUrl in config.serverInfoByUrl!.entries) {
        urlsByRelRoute[infoByUrl.key] = UrlFormatUtility.createServerBaseUrls(infoByUrl.value);
      }
    }

    _serverUrls = ServerUrls(
      defaultUrl: UrlFormatUtility.createServerBaseUrls(config.defaultServerInfo),
      byRelRoute: urlsByRelRoute,
    );

    _serverRequester = ServerRequester(
      logsHelper: _logsHelper,
      serverUrls: _serverUrls,
      defaultTimeout: config.defaultTimeout,
      maxParallelRequestsNb: config.maxParallelRequestsNb,
    );

    await _serverRequester.initLifeCycle();

    _absServerLogin = await createServerLogin(
      serverRequester: _serverRequester,
      parentLogsHelper: _logsHelper,
    );

    if (!(await _absServerLogin!.initLogin())) {
      throw Exception("An error occurred when tried to init the abs server login");
    }
  }

  /// Called to initialize the manager after the view is loaded
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // In that case, the context will stay the same
    // ignore: use_build_context_synchronously
    await _serverRequester.initAfterView(context);
  }

  /// {@template act_http_client_manager.AbsServerReqManager.executeRequest}
  /// This method requests the third server and manages the login (if it exists and if it's
  /// necessary).
  ///
  /// [requestParam] is the request to execute on the third server.
  /// If [ifExistUseAuth] is equals to true and the linked login class exists, we will try to use
  /// authentication with the request.
  /// [retryRequestIfErrorNb] defines the nb of times we want to repeat the request if it hasn't
  /// worked. If the login fails because of a global error, the login policy chosen will be applied,
  /// and this parameter not used. If the login fails because the credentials are not correct, this
  /// is not used and the request won't be repeated.
  /// [retryTimeout] defines the timeout to wait between each retry. If no timeout is given, no wait
  /// is done.
  /// If given, [parseRespBody] is used to parse the response body.
  /// {@endtemplate}
  Future<RequestResponse<ParsedRespBody>> executeRequest<ParsedRespBody, RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
    ParsedRespBody? Function(RespBody body)? parseRespBody,
  }) async {
    var retryRequestNb = 0;
    var loginRetryNb = 0;
    final localAbsServerLogin = _absServerLogin;

    var globalResult = RequestStatus.globalError;
    Response? response;
    ParsedRespBody? castedBody;

    while (globalResult != RequestStatus.success && retryRequestNb <= retryRequestIfErrorNb) {
      // We reset the previous specific error
      globalResult = RequestStatus.globalError;

      retryRequestNb++;
      var loginResult = RequestStatus.success;

      if (ifExistUseAuth && localAbsServerLogin != null) {
        loginResult = await localAbsServerLogin.manageLogInWithRequest(requestParam);

        if (loginResult != RequestStatus.success) {
          globalResult = RequestStatus.loginError;
          await localAbsServerLogin.clearLogins();

          if (loginResult == RequestStatus.loginError) {
            _logsHelper.e("There is a problem when tried to log-in, may be the logins aren't "
                "right?");
            return RequestResponse(status: globalResult);
          }

          _logsHelper.w("An error occurred when managing the login of a request");
        }
      }

      if (loginResult == RequestStatus.success) {
        (globalResult, response, castedBody) =
            (await _serverRequester.executeRequestWithoutAuth<ParsedRespBody, RespBody>(
          requestParam: requestParam,
          parseRespBody: parseRespBody,
        ))
                .toPatterns();

        if (localAbsServerLogin != null && globalResult == RequestStatus.loginError) {
          // We receive a login error, our logins aren't correct, we clear them
          await localAbsServerLogin.clearLogins();

          if (localAbsServerLogin.loginFailPolicy == LoginFailPolicy.retryOnceIfLoginFails &&
              loginRetryNb == 0) {
            loginRetryNb++;
            retryRequestNb--;
          }
        }
      }

      if (globalResult != RequestStatus.success && retryTimeout != null) {
        await Future.delayed(retryTimeout);
      }
    }

    return RequestResponse(status: globalResult, response: response, castedBody: castedBody);
  }

  /// {@macro act_http_client_manager.AbsServerReqManager.executeRequest}
  ///
  /// This method can be used when we expect that the response body has a MIME type, for instance: a
  /// JSON object or array.
  Future<RequestResponse<RespBody>> executeRequestWithMimeRespBody<RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async =>
      executeRequest<RespBody, RespBody>(
          requestParam: requestParam,
          ifExistUseAuth: ifExistUseAuth,
          retryRequestIfErrorNb: retryRequestIfErrorNb,
          retryTimeout: retryTimeout);

  /// {@macro act_http_client_manager.AbsServerReqManager.executeRequest}
  ///
  /// This method can be used when we know we will receive a JSON object as response and we want to
  /// parse the JSON object to a particular class.
  Future<RequestResponse<RespBody>> executeRequestWithJsonObjRespBody<RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
    required RespBody? Function(Map<String, dynamic> body) parseRespBody,
  }) async =>
      executeRequest<RespBody, Map<String, dynamic>>(
        requestParam: requestParam.copyWith(
          expectedMimeType: MimeTypes.json,
        ),
        ifExistUseAuth: ifExistUseAuth,
        retryRequestIfErrorNb: retryRequestIfErrorNb,
        retryTimeout: retryTimeout,
        parseRespBody: parseRespBody,
      );

  /// {@macro act_http_client_manager.AbsServerReqManager.executeRequest}
  ///
  /// This method can be used when we know we will receive a JSON array as response and we want to
  /// parse the JSON array to a particular class.
  Future<RequestResponse<RespBody>> executeRequestWithJsonArrayRespBody<RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
    required RespBody? Function(List<dynamic> body) parseRespBody,
  }) async =>
      executeRequest<RespBody, List<dynamic>>(
        requestParam: requestParam.copyWith(
          expectedMimeType: MimeTypes.json,
        ),
        ifExistUseAuth: ifExistUseAuth,
        retryRequestIfErrorNb: retryRequestIfErrorNb,
        retryTimeout: retryTimeout,
        parseRespBody: parseRespBody,
      );

  /// {@macro act_http_client_manager.AbsServerReqManager.executeRequest}
  ///
  /// This method can be used when we know we will receive a JSON array as response and we want to
  /// parse the JSON array to a particular class list.
  Future<RequestResponse<List<RespBody>>> executeRequestWithJsonObjArrayRespBody<RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
    required RespBody? Function(Map<String, dynamic> body) parseRespBody,
  }) async =>
      executeRequest<List<RespBody>, List<dynamic>>(
        requestParam: requestParam.copyWith(
          expectedMimeType: MimeTypes.json,
        ),
        ifExistUseAuth: ifExistUseAuth,
        retryRequestIfErrorNb: retryRequestIfErrorNb,
        retryTimeout: retryTimeout,
        parseRespBody: (bodyList) => _parseJsonObjectArray(
          jsonArray: bodyList,
          parseRespBody: parseRespBody,
        ),
      );

  /// {@template act_http_client_manager.AbsServerReqManager.getRequesterConfig}
  /// The method returns the requester configuration to apply
  /// {@endtemplate}
  @protected
  Future<RequesterConfig> getRequesterConfig();

  /// {@template act_http_client_manager.AbsServerReqManager.createServerLogin}
  /// Create the server login
  /// {@endtemplate}
  @protected
  Future<T> createServerLogin({
    required ServerRequester serverRequester,
    required LogsHelper parentLogsHelper,
  });

  /// Parse a JSON object to a [RespBody] object
  ///
  /// This method is used to parse a JSON array which contains JSON object
  static List<RespBody>? _parseJsonObjectArray<RespBody>({
    required List<dynamic> jsonArray,
    required RespBody? Function(Map<String, dynamic> body) parseRespBody,
  }) {
    final tmpList = <RespBody>[];
    for (final obj in jsonArray) {
      if (obj is! Map<String, dynamic>) {
        appLogger().w("The element in the list isn't a JSON object");
        return null;
      }

      final tmpParsed = parseRespBody(obj);
      if (tmpParsed == null) {
        appLogger().w("The JSON object in the received array isn't the type we expect");
        return null;
      }

      tmpList.add(tmpParsed);
    }
    return tmpList;
  }

  /// The dispose method
  @override
  Future<void> disposeLifeCycle() async {
    await _serverRequester.disposeLifeCycle();
    await super.disposeLifeCycle();
  }
}
