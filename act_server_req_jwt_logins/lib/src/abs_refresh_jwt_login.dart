// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_jwt_logins/src/abs_jwt_login.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// This login is used to manage an authentication with a refresh token
abstract class AbsRefreshJwtLogin extends AbsJwtLogin {
  /// Class constructor
  AbsRefreshJwtLogin({
    required super.serverRequester,
    required super.logsHelper,
    super.loginFailPolicy,
    super.headerAuthKey,
    super.headerAuthValueFormatted,
    super.verifyTokenExpirationDate,
  });

  /// {@template act_server_req_jwt_logins.AbsRefreshJwtLogin.getRefreshRequest}
  /// This method returns the request to execute in order to refresh the token from the server and
  /// get the JWT
  /// {@endtemplate}
  @protected
  Future<RequestParam?> getRefreshRequest();

  /// {@template act_server_req_jwt_logins.AbsRefreshJwtLogin.parseRefreshResponse}
  /// Parse the response received after having executed the login request
  /// {@endtemplate}
  @protected
  Future<AuthTokens?> parseRefreshResponse(RequestResponse response);

  /// {@macro act_server_req_jwt_logins.AbsJwtLogin.managedIntermediateProcess}
  @protected
  @override
  Future<bool> managedIntermediateProcess() async {
    if (!verifyTokenInfo(tokensInfo?.refreshToken)) {
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

    await updateTokenInfo(jwtResponse);

    logsHelper.d("New tokens retrieved from server and refresh request");
    return true;
  }
}
