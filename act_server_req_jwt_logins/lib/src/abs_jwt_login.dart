// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// This class manages a login and authentication linked to a JWT. The JWT is generated thanks to
/// a first non authenticated request.
///
/// The token is added to the request headers.
abstract class AbsJwtLogin extends AbsServerLogin {
  /// This is the controller used to emit a new [AuthTokens] got from server and valid.
  ///
  /// Emits null, if no more valid tokens are available
  final StreamController<AuthTokens?> _newTokensCtrl;

  /// This is the header key where to set the token
  final String headerAuthKey;

  /// The token is inserted into this formatted value string
  /// The token is inserted in the value each time '{token}' is encountered
  final String headerAuthValueFormatted;

  /// If true, the expiration date of the token is verified each time a request is made to the
  /// server. If false, the expiration date isn't verified and the token may fails at any time.
  final bool verifyTokenExpirationDate;

  /// The tokens to use in order to request the server
  AuthTokens? _tokensInfo;

  /// Get the access token
  AuthTokens? get tokensInfo => _tokensInfo;

  /// This is the stream of the [_newTokensCtrl]
  Stream<AuthTokens?> get newTokensStream => _newTokensCtrl.stream;

  /// Class constructor
  AbsJwtLogin({
    required super.serverRequester,
    required super.logsHelper,
    super.loginFailPolicy,
    this.headerAuthKey = ServerReqConstants.authorizationHeader,
    this.headerAuthValueFormatted = AuthConstants.authBearer,
    this.verifyTokenExpirationDate = true,
  })  : _tokensInfo = null,
        _newTokensCtrl = StreamController.broadcast();

  /// {@macro act_server_req_manager.AbsServerLogin.manageLogInWithRequest}
  @override
  Future<RequestStatus> manageLogInWithRequest(RequestParam requestParam) async {
    var accessToken = _tokensInfo?.accessToken;
    if (verifyTokenInfo(accessToken)) {
      // Token is valid
    } else if (await managedIntermediateProcess()) {
      // The intermediate process has worked
    } else {
      final result = await _manageLogInToServerFromMemory();

      if (result != RequestStatus.success) {
        // Nothing has worked, we stop here
        await clearLogins();
        return result;
      }
    }

    accessToken = _tokensInfo?.accessToken;
    // Even if the verifyTokenInfo method test if the _tokenInfo is undefined
    // I redo the test to avoid to have a warning with the next lines (and because the content
    // of the method may change in future and we may forget to apply the modifications here)
    if (accessToken == null || !verifyTokenInfo(accessToken)) {
      logsHelper.e("The token info aren't correct but we succeeded all the login process, that "
          "can't happen but it happened...");
      return RequestStatus.globalError;
    }

    _formatHeaderWithToken(requestParam, accessToken.raw);
    return RequestStatus.success;
  }

  /// {@macro act_server_req_manager.AbsServerLogin.clearLogins}
  @override
  Future<void> clearLogins() async {
    if (_tokensInfo != null) {
      logsHelper.d("A problem occurred, we clear the token");
      _tokensInfo = null;
      _newTokensCtrl.add(null);
    }
  }

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.managedIntermediateProcess}
  /// This methods is useful if the derived classes have themselves an another method to logIn into
  /// the server.
  /// {@endtemplate}
  @protected
  Future<bool> managedIntermediateProcess() async => false;

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.getLoginRequestFromMemory}
  /// This method returns the request to execute in order to logIn into the server and get the JWT
  /// execute
  /// {@endtemplate}
  @protected
  Future<RequestParam?> getLoginRequestFromMemory();

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.parseLoginResponse}
  /// Parse the response received after having executed the login request
  /// {@endtemplate}
  @protected
  Future<AuthTokens?> parseLoginResponse(RequestResponse response);

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.updateTokenInfo}
  /// Update the token info from the server
  /// {@endtemplate}
  @protected
  Future<void> updateTokenInfo(AuthTokens authTokens) async {
    if (authTokens == _tokensInfo) {
      // Nothing to do
      return;
    }

    _tokensInfo = authTokens;
    _newTokensCtrl.add(_tokensInfo);
  }

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.verifyTokenInfo}
  /// This method verifies the token information retrieved from the server.
  ///
  /// If no expiration date is set in the token, we consider that there is no problem, but the
  /// token may fails at any time.
  /// {@endtemplate}
  @protected
  bool verifyTokenInfo(AuthToken? tokenInfo) =>
      tokenInfo != null && tokenInfo.isValid(testExpiration: verifyTokenExpirationDate);

  /// {@template act_server_req_jwt_logins.AbsJwtLogin.manageLogInToServer}
  /// This manages the logIn into the server via the given login request
  /// {@endtemplate}
  @protected
  Future<RequestStatus> manageLogInToServer({
    required RequestParam requestParam,
  }) async {
    final response = await serverRequester.executeRequestWithoutAuth(requestParam: requestParam);

    if (response.status != RequestStatus.success) {
      logsHelper.w("A problem occurred when trying to log in to the app");
      return response.status;
    }

    final jwtResponse = await parseLoginResponse(response);

    if (jwtResponse == null) {
      logsHelper.w("A problem occurred when parsed the response received to get the JWT login "
          "token");
      return RequestStatus.globalError;
    }

    await updateTokenInfo(jwtResponse);

    logsHelper.d("New token retrieved from server");
    return RequestStatus.success;
  }

  /// This manages the logIn into the server via the [getLoginRequestFromMemory] executed. By calling
  /// [manageLogInToServer]
  Future<RequestStatus> _manageLogInToServerFromMemory() async {
    final loginRequest = await getLoginRequestFromMemory();

    if (loginRequest == null) {
      logsHelper.w("Can't create the JWT token login request");
      return RequestStatus.globalError;
    }

    final response = await serverRequester.executeRequestWithoutAuth(requestParam: loginRequest);

    if (response.status != RequestStatus.success) {
      logsHelper.w("A problem occurred when trying to log in to the app");
      return response.status;
    }

    final jwtResponse = await parseLoginResponse(response);

    if (jwtResponse == null) {
      logsHelper.w("A problem occurred when parsed the response received to get the JWT login "
          "token");
      return RequestStatus.globalError;
    }

    await updateTokenInfo(jwtResponse);

    logsHelper.d("New token retrieved from server");
    return RequestStatus.success;
  }

  /// This method adds the token into the headers of the future request
  void _formatHeaderWithToken(RequestParam futureRequestParam, String token) {
    futureRequestParam.headers[headerAuthKey] = headerAuthValueFormatted.replaceAll(
      AuthConstants.tokenBearerKey,
      token,
    );
  }
}
