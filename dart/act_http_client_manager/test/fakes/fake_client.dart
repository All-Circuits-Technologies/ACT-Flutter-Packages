// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// The login of a server, which answers what the test lined up.
class FakeClientLogin extends AbsHttpClientLogin {
  /// What the login answers when it is initialized.
  final bool initResult;

  /// What the login answers to the requests, one per request, in order.
  ///
  /// Once the list is empty, every request is answered with [defaultResult].
  final List<RequestStatus> results = [];

  /// The requests the login was asked to sign, in the order it was asked.
  final List<RequestParam> signed = [];

  /// The number of times the logins were cleared.
  int clearCount = 0;

  /// What the login answers once the lined up answers have all been given.
  RequestStatus defaultResult;

  /// Class constructor
  FakeClientLogin({
    required super.serverRequester,
    required super.logsHelper,
    super.loginFailPolicy,
    this.initResult = true,
    this.defaultResult = RequestStatus.success,
  });

  /// {@macro act_http_client_manager.AbsServerLogin.initLogin}
  @override
  Future<bool> initLogin() async => initResult;

  /// {@macro act_http_client_manager.AbsServerLogin.manageLogInWithRequest}
  @override
  Future<RequestStatus> manageLogInWithRequest(RequestParam requestParam) async {
    signed.add(requestParam);

    return results.isEmpty ? defaultResult : results.removeAt(0);
  }

  /// {@macro act_http_client_manager.AbsServerLogin.clearLogins}
  ///
  /// The abstract method has no body to call back into, which is why this one calls no super.
  // ignore: must_call_super
  @override
  Future<void> clearLogins() async => clearCount++;
}

/// The manager of an application which requests a server, over the configuration of the test.
class FakeClientManager extends AbsHttpClientManager<FakeClientLogin?> {
  /// The configuration the manager is initialized with.
  final RequesterConfig config;

  /// Builds the login of the manager, or answers null for an application which needs none.
  final FakeClientLogin? Function(ServerRequester requester, LogsHelper logsHelper)? loginBuilder;

  /// The login the manager built, once it has been initialized.
  FakeClientLogin? builtLogin;

  /// Class constructor
  FakeClientManager({required this.config, this.loginBuilder});

  /// {@macro act_http_client_manager.AbsServerReqManager.getRequesterConfig}
  @override
  Future<RequesterConfig> getRequesterConfig() async => config;

  /// {@macro act_http_client_manager.AbsServerReqManager.createServerLogin}
  @override
  Future<FakeClientLogin?> createServerLogin({
    required ServerRequester serverRequester,
    required LogsHelper parentLogsHelper,
  }) async {
    builtLogin = loginBuilder?.call(serverRequester, parentLogsHelper);

    return builtLogin;
  }
}

/// The builder of the manager of an application which requests a server.
class FakeClientBuilder extends AbsHttpClientBuilder<FakeClientManager> {
  /// Class constructor
  const FakeClientBuilder(super.factory);
}
