// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_jwt_logins/act_server_req_jwt_logins.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// This is the authentication storage linked to the JWT login
mixin MixinAuthStorageJwtLogin on AbsJwtLogin {
  /// {@template act_server_req_jwt_logins.MixinAuthStorageJwtLogin.storageService}
  /// This is the storage service linked to the JWT login
  /// {@endtemplate}
  MixinAuthStorageService? get storageService;

  /// {@macro act_server_req_manager.AbsServerLogin.initLogin}
  @override
  Future<bool> initLogin() async {
    final result = await super.initLogin();
    if (!result) {
      return false;
    }

    final tokens = await storageService?.loadTokens();
    if (tokens == null) {
      // There is no tokens in memory, no need to go further
      return true;
    }

    await updateTokenInfo(tokens, saveTokenInMemory: false);
    return true;
  }

  /// {@macro act_server_req_manager.AbsServerLogin.manageLogInWithRequest}
  @override
  Future<RequestStatus> manageLogInWithRequest(RequestParam requestParam) async {
    // Before trying to use the tokens in cache, we verify if the tokens has been updated in the
    // shared memory (which can be the case if we use parallels views (for instance tabs in
    // web browser)).
    final tokens = await storageService?.loadTokens();
    if (tokens != null) {
      await updateTokenInfo(tokens, saveTokenInMemory: false);
    }
    return super.manageLogInWithRequest(requestParam);
  }

  /// {@macro act_server_req_jwt_logins.AbsJwtLogin.updateTokenInfo}
  @override
  Future<void> updateTokenInfo(AuthTokens authTokens, {bool saveTokenInMemory = true}) async {
    await super.updateTokenInfo(authTokens);
    if (saveTokenInMemory) {
      await storageService?.storeTokens(tokens: authTokens);
    }
  }
}
