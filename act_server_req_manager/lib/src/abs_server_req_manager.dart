// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/src/abs_server_login.dart';
import 'package:act_server_req_manager/src/helpers/url_format_utility.dart';
import 'package:act_server_req_manager/src/models/request_param.dart';
import 'package:act_server_req_manager/src/models/request_response.dart';
import 'package:act_server_req_manager/src/models/requester_config.dart';
import 'package:act_server_req_manager/src/models/server_urls.dart';
import 'package:act_server_req_manager/src/server_requester.dart';
import 'package:act_server_req_manager/src/types/login_fail_policy.dart';
import 'package:act_server_req_manager/src/types/request_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

/// Builder of the [AbsServerReqManager] manager
abstract class AbsServerReqBuilder<T extends AbsServerReqManager> extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsServerReqBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This class defines a manager useful to request a third server.
///
/// A login process may be added to it, if the third server needs a login to execute requests
abstract class AbsServerReqManager<T extends AbsServerLogin?> extends AbsWithLifeCycle {
  /// This contains the base of all URL to request the server: the default one and the overrided
  /// URLs depending of the relative routes
  /// The server URLs are formatted liked that: http(s)://{hostname}:{port}/{baseUrl}
  late final ServerUrls _serverUrls;

  /// This is the logs helper linked to the request manager
  late final LogsHelper _logsHelper;

  /// {@template act_server_req_manager.AbsServerReqManager.absServerLogin}
  /// This is the server login to use in order to logIn into the server, if undefined, there is no
  /// authentication to the server
  /// {@endtemplate}
  late final T _absServerLogin;

  /// {@macro act_server_req_manager.AbsServerReqManager.absServerLogin}
  @protected
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
    );

    await _serverRequester.initLifeCycle();

    _absServerLogin = await createServerLogin(_serverRequester);

    if (_absServerLogin != null && !(await _absServerLogin!.initLogin())) {
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

  /// This method requests the third server and manages the login (if it exists and if it's
  /// necessary).
  ///
  /// The method is protected to force to create a specific method for our usage, in order to
  /// avoid to have to give each template each time we want to request the third server.
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
  Future<RequestResponse<RespBody>> executeRequest<RespBody>({
    required RequestParam requestParam,
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async {
    var retryRequestNb = 0;
    var loginRetryNb = 0;
    final localAbsServerLogin = _absServerLogin;

    var globalResult = RequestStatus.globalError;
    Response? response;
    RespBody? castedBody;

    while (globalResult != RequestStatus.success && retryRequestNb <= retryRequestIfErrorNb) {
      // We reset the previous specific error
      globalResult = RequestStatus.globalError;

      retryRequestNb++;
      var loginResult = RequestStatus.success;

      if (ifExistUseAuth && localAbsServerLogin != null) {
        loginResult = await localAbsServerLogin.manageLogin(requestParam);

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
            (await _serverRequester.executeRequestWithoutAuth<RespBody>(requestParam)).toPatterns();

        if (localAbsServerLogin != null &&
            localAbsServerLogin.loginFailPolicy == LoginFailPolicy.retryOnceIfLoginFails &&
            globalResult == RequestStatus.loginError &&
            loginRetryNb == 0) {
          // We clear the login info
          await localAbsServerLogin.clearLogins();
          loginRetryNb++;
          retryRequestNb--;
        }
      }

      if (globalResult != RequestStatus.success && retryTimeout != null) {
        await Future.delayed(retryTimeout);
      }
    }

    return RequestResponse(status: globalResult, response: response, castedBody: castedBody);
  }

  /// The method returns the requester configuration to apply
  @protected
  Future<RequesterConfig> getRequesterConfig();

  /// Create the server login
  @protected
  Future<T> createServerLogin(ServerRequester serverRequester);

  /// The dispose method
  @override
  Future<void> disposeLifeCycle() async {
    await _serverRequester.disposeLifeCycle();
    await super.disposeLifeCycle();
  }
}
