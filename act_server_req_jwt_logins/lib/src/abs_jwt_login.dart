// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_jwt_logins/src/jwt_login_constants.dart' as jwt_login_constants;
import 'package:act_server_req_jwt_logins/src/models/token_answer.dart';
import 'package:act_server_req_jwt_logins/src/models/token_info.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:flutter/cupertino.dart';

/// This class manages a login and authentication linked to a JWT. The JWT is generated thanks to
/// a first non authenticated request.
///
/// The token is added to the request headers.
abstract class AbsJwtLogin<T extends TokenAnswer> extends AbsServerLogin {
  /// The access token to use in order to request the server
  TokenInfo? _tokenInfo;

  /// This is the header key where to set the token
  final String headerAuthKey;

  /// The token is inserted into this formatted value string
  /// The token is inserted in the value each time '{token}' is encountered
  final String headerAuthValueFormatted;

  /// Class constructor
  AbsJwtLogin({
    required super.serverRequester,
    required super.loginFailPolicy,
    required super.logsHelper,
    this.headerAuthKey = ServerReqConstants.authorizationHeader,
    this.headerAuthValueFormatted = jwt_login_constants.authBearer,
  }) : _tokenInfo = null;

  /// This method manages the login to the third server if it's needed. It also adds to the
  /// request all the authentication information which are asked by the third server.
  @override
  Future<RequestResult> manageLogin(RequestParam requestParam) async {
    if (verifyTokenInfo(_tokenInfo)) {
      // Token is valid
    } else if (await managedIntermediateProcess()) {
      // The intermediate process has worked
    } else {
      final result = await _manageLogInToServer();

      if (result != RequestResult.success) {
        // Nothing has worked, we stop here
        await clearLogins();
        return result;
      }
    }

    // Even if the verifyTokenInfo method test if the _tokenInfo is undefined
    // I redo the test to avoid to have a warning with the next lines (and because the content
    // of the method may change in future and we may forget to apply the modifications here)
    if (_tokenInfo == null || !verifyTokenInfo(_tokenInfo)) {
      logsHelper.e("The token info aren't correct but we succeeded all the login process, that "
          "can't happen but it happened...");
      return RequestResult.globalError;
    }

    _formatHeaderWithToken(requestParam, _tokenInfo!.token);
    return RequestResult.success;
  }

  /// Clear the logins
  @override
  Future<void> clearLogins() async {
    if (_tokenInfo != null) {
      logsHelper.d("A problem occurred, we clear the token");
      _tokenInfo = null;
    }
  }

  /// This methods is useful if the derived classes have themselves an another method to logIn into
  /// the server.
  @protected
  Future<bool> managedIntermediateProcess() async => false;

  /// Manage the response received after having executed the login request but for an intermediate
  /// process.
  ///
  /// This intermediate process is useful if you need to parse more elements from derived classes
  @protected
  Future<bool> manageLoginResponseForInterProcess(T jwtResponse) async => true;

  /// This method returns the request to execute in order to logIn into the server and get the JWT
  /// execute
  @protected
  Future<RequestParam?> getLoginRequest();

  /// Parse the response received after having executed the login request
  @protected
  Future<T?> parseLoginResponse(RequestResponse response);

  /// Update the token info from the server
  @protected
  void updateTokenInfo(T jwtResponse) {
    _tokenInfo ??= TokenInfo(token: "");

    _tokenInfo!.token = jwtResponse.token;

    if (jwtResponse.expInMs != null) {
      _tokenInfo!.tokenExpDate = DateTime.fromMillisecondsSinceEpoch(
        jwtResponse.expInMs!,
        isUtc: true,
      );
    }
  }

  /// This method verifies the token information retrieved from the server.
  ///
  /// If no expiration date is set in the token, we consider that there is no problem, but the
  /// token may fails at any time.
  @protected
  static bool verifyTokenInfo(TokenInfo? tokenInfo) => tokenInfo != null && tokenInfo.isValid;

  /// This manages the logIn into the server via the [getLoginRequest] executed
  Future<RequestResult> _manageLogInToServer() async {
    final loginRequest = await getLoginRequest();

    if (loginRequest == null) {
      logsHelper.w("Can't create the JWT token login request");
      return RequestResult.globalError;
    }

    final response = await serverRequester.executeRequestWithoutAuth(loginRequest);

    if (response.result != RequestResult.success) {
      logsHelper.w("A problem occurred when tried to login to the app");
      return response.result;
    }

    final jwtResponse = await parseLoginResponse(response);

    if (jwtResponse == null) {
      logsHelper.w("A problem occurred when parsed the response received to get the JWT login "
          "token");
      return RequestResult.globalError;
    }

    if (!(await manageLoginResponseForInterProcess(jwtResponse))) {
      logsHelper.w("A problem occurred when parsed the response received by the intermediate "
          "process");
      return RequestResult.globalError;
    }

    updateTokenInfo(jwtResponse);

    logsHelper.d("New token retrieved from server");
    return RequestResult.success;
  }

  /// This method adds the token into the headers of the future request
  void _formatHeaderWithToken(RequestParam futureRequestParam, String token) {
    futureRequestParam.headers[headerAuthKey] = headerAuthValueFormatted.replaceAll(
      jwt_login_constants.tokenBearerKey,
      token,
    );
  }
}
