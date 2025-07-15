// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_jwt_logins/src/abs_jwt_login.dart';
import 'package:act_server_req_jwt_logins/src/models/refresh_token_answer.dart';
import 'package:act_server_req_jwt_logins/src/models/token_info.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:flutter/cupertino.dart';

/// This login is used to manage an authentication with a refresh token
abstract class AbsRefreshJwtLogin extends AbsJwtLogin<RefreshTokenAnswer> {
  /// The refresh token to request the server
  TokenInfo? _refreshTokenInfo;

  /// Getter of the refresh token
  @protected
  TokenInfo? get refreshTokenInfo => _refreshTokenInfo;

  /// Class constructor
  AbsRefreshJwtLogin({
    required super.serverRequester,
    required super.loginFailPolicy,
    required super.logsHelper,
    super.headerAuthKey = ServerReqConstants.authorizationHeader,
    super.headerAuthValueFormatted = AuthConstants.authBearer,
  }) : _refreshTokenInfo = null;

  /// This method returns the request to execute in order to refresh the token from the server and
  /// get the JWT
  @protected
  Future<RequestParam?> getRefreshRequest();

  /// Parse the response received after having executed the login request
  @protected
  Future<RefreshTokenAnswer?> parseRefreshResponse(RequestResponse response);

  /// Manage the response received after having executed the login request but for getting the
  /// refresh token.
  @protected
  @override
  Future<bool> manageLoginResponseForInterProcess(RefreshTokenAnswer jwtResponse) async {
    // No need to update token info, it's already done in the caller method
    _updateRefreshTokenInfo(jwtResponse);

    logsHelper.d("New refresh token retrieved from server and login request");
    return true;
  }

  /// Try to refresh the token
  @protected
  @override
  Future<bool> managedIntermediateProcess() async {
    if (!AbsJwtLogin.verifyTokenInfo(_refreshTokenInfo)) {
      logsHelper.i("The refresh token is valid, we can't try to get tokens");
      return false;
    }

    final loginRequest = await getRefreshRequest();

    if (loginRequest == null) {
      logsHelper.w("Can't create the JWT refresh login request");
      return false;
    }

    final response = await serverRequester.executeRequestWithoutAuth(requestParam: loginRequest);

    if (response.status != RequestStatus.success) {
      logsHelper.w("A problem occurred when trying to get the refresh token");
      return false;
    }

    final jwtResponse = await parseRefreshResponse(response);

    if (jwtResponse == null) {
      logsHelper.w("A problem occurred when parsed the refresh response received to get the JWT "
          "login token");
      return false;
    }

    updateTokenInfo(jwtResponse);

    _updateRefreshTokenInfo(jwtResponse);

    logsHelper.d("New tokens retrieved from server and refresh request");
    return true;
  }

  /// Clear the logins
  @override
  Future<void> clearLogins() async {
    await super.clearLogins();

    if (_refreshTokenInfo != null) {
      logsHelper.d("A problem occurred, we clear the refresh token");
      _refreshTokenInfo = null;
    }
  }

  /// Update the refresh token information from the refresh token answer
  void _updateRefreshTokenInfo(RefreshTokenAnswer jwtResponse) {
    _refreshTokenInfo ??= jwtResponse.toRefreshTokenInfo();
  }
}
