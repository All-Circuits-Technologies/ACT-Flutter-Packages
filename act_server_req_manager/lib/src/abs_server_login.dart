// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/src/models/request_param.dart';
import 'package:act_server_req_manager/src/server_requester.dart';
import 'package:act_server_req_manager/src/types/login_fail_policy.dart';
import 'package:act_server_req_manager/src/types/request_result.dart';
import 'package:flutter/cupertino.dart';

/// This class manages the log in to a specific server and the adding of credentials in the other
/// requests
abstract class AbsServerLogin {
  /// This is the server requester linked to the class, which allows to request the third server
  final ServerRequester serverRequester;

  /// This is the login fail policy to apply to the third server authentication
  final LoginFailPolicy loginFailPolicy;

  /// This represents the logs helper linked to the class
  final LogsHelper logsHelper;

  /// Class constructor
  AbsServerLogin({
    required this.serverRequester,
    required this.logsHelper,
    this.loginFailPolicy = LoginFailPolicy.errorIfLoginFails,
  });

  /// This methods may be used by derived classes to initialize async login
  Future<bool> initLogin() async => true;

  /// This methods manages the login to the third server if it's needed. It also adds to the
  /// request all the authentication information which are asked by the third server.
  Future<RequestResult> manageLogin(RequestParam requestParam);

  /// Clear the logins
  @mustCallSuper
  Future<void> clearLogins();
}
