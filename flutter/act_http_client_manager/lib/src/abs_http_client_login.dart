// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/src/models/request_param.dart';
import 'package:act_http_client_manager/src/server_requester.dart';
import 'package:act_http_client_manager/src/types/login_fail_policy.dart';
import 'package:act_http_client_manager/src/types/request_status.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';

/// This class manages the log in to a specific server and the adding of credentials in the other
/// requests
abstract class AbsHttpClientLogin {
  /// This is the server requester linked to the class, which allows to request the third server
  final ServerRequester serverRequester;

  /// This is the login fail policy to apply to the third server authentication
  final LoginFailPolicy loginFailPolicy;

  /// This represents the logs helper linked to the class
  final LogsHelper logsHelper;

  /// Class constructor
  AbsHttpClientLogin({
    required this.serverRequester,
    required this.logsHelper,
    this.loginFailPolicy = LoginFailPolicy.errorIfLoginFails,
  });

  /// {@template act_http_client_manager.AbsServerLogin.initLogin}
  /// This methods may be used by derived classes to initialize async login
  /// {@endtemplate}
  Future<bool> initLogin() async => true;

  /// {@template act_http_client_manager.AbsServerLogin.manageLogInWithRequest}
  /// This methods manages the login to the third server if it's needed. It also adds to the
  /// request all the authentication information which are asked by the third server.
  /// {@endtemplate}
  Future<RequestStatus> manageLogInWithRequest(RequestParam requestParam);

  /// {@template act_http_client_manager.AbsServerLogin.clearLogins}
  /// Clear the logins
  /// {@endtemplate}
  @mustCallSuper
  Future<void> clearLogins();
}
