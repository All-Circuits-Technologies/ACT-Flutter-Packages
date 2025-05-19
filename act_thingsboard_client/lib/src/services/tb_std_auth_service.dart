// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/src/managers/tb_no_auth_server_req_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the service used to authenticate the user with the standard Thingsboard authentications
class TbStdAuthService extends AbsWithLifeCycle with MixinAuthService {
  /// This is the log category linked to the auth service
  static const _logsCategory = "tbAuth";

  /// This is the controller linked to the authentication status
  final StreamController<AuthStatus> _authStatusCtrl;

  /// This is the [TbNoAuthServerReqManager] used to request the server
  late final TbNoAuthServerReqManager _noAuthReqManager;

  /// The mutex is used to prevent to authenticate the server in parallel
  final Mutex _mutex;

  /// This is the logs helper
  final LogsHelper _logsHelper;

  /// The current authentication status
  AuthStatus _authStatus;

  /// The service used to store the authentication info
  MixinAuthStorageService? _storageService;

  /// {@macro act_shared_auth.MixinAuthService.storageService}
  @override
  MixinAuthStorageService? get storageService => _storageService;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

  /// Class constructor
  TbStdAuthService()
      : _authStatus = AuthStatus.signedOut,
        _authStatusCtrl = StreamController<AuthStatus>.broadcast(),
        _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory),
        _mutex = Mutex();

  /// Init the service
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _noAuthReqManager = globalGetIt().get<TbNoAuthServerReqManager>();

    if (_storageService == null) {
      // Nothing more to do
      return;
    }

    await _unSafeGetTokens(initTokensLoading: _storageService!.loadTokens);
  }

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async =>
      _storageService = storageService;

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) =>
      _mutex.protect(() async => _unSafeSignInUser(username: username, password: password));

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() => _mutex.protect(() async {
        await _noAuthReqManager.tbClient.logout();
        await _storageService?.clearUserIds();

        _setAuthStatus(AuthStatus.signedOut);

        return true;
      });

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() => _mutex.protect(() async => _authStatus == AuthStatus.signedIn);

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() => _mutex.protect(() async => _unSafeGetTokens(
        initTokensLoading: _getTokensFromTbClient,
      ));

  /// This method is useful to update, if needed, the [AuthStatus] by calling [_setAuthStatus].
  ///
  /// It wraps a [request] and tests the result of request with method [testResult] to know if we
  /// need to call [_setAuthStatus] method.
  ///
  /// If [testResult] method returns null, it means that we have nothing to set.
  ///
  /// Return what the [request] method has returned
  Future<T> _wrapSetAuthUser<T>(
    Future<T> Function() request, {
    required AuthStatus? Function(T result) testResult,
  }) async {
    final result = await request();
    final authStatus = testResult(result);

    if (authStatus != null) {
      _setAuthStatus(authStatus);
    }

    return result;
  }

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  ///
  /// Sign in the user without the mutex protection
  Future<AuthSignInResult> _unSafeSignInUser({
    required String username,
    required String password,
  }) =>
      _wrapSetAuthUser(() async {
        final loginResponse = await _noAuthReqManager.request(
          (tbClient) async => tbClient.login(LoginRequest(username, password)),
        );

        if (loginResponse.status != RequestStatus.success) {
          _logsHelper
              .w("A problem occurred when tried to sign in the user thanks to the identifiers "
                  "given");
          return AuthSignInResult(status: loginResponse.status.signInStatus);
        }

        if (await _storageService?.isUserIdsStorageSupported() ?? false) {
          await _storageService?.storeUserIds(username: username, password: password);
        }

        return const AuthSignInResult(status: AuthSignInStatus.done);
      }, testResult: (result) {
        if (result.status == AuthSignInStatus.done) {
          return AuthStatus.signedIn;
        }

        if (result.status == AuthSignInStatus.sessionExpired) {
          return AuthStatus.sessionExpired;
        }

        return null;
      });

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  ///
  /// Get the tokens without the mutex protection.
  ///
  /// [initTokensLoading] is used to get the tokens from memory at start
  Future<AuthTokens?> _unSafeGetTokens({
    required FutureOr<AuthTokens?> Function() initTokensLoading,
  }) =>
      _wrapSetAuthUser(() async {
        if (await _tryToLogInFromTokens(loadTokens: initTokensLoading)) {
          final tokens = _getTokensFromTbClient();
          if (tokens == null) {
            appLogger()
                .e("We try to log in from tokens, it succeeds but there is no value stored in "
                    "tb client (which can't happen)");
            return null;
          }

          _setAuthStatus(AuthStatus.signedIn);
          return tokens;
        }

        if (_storageService == null || !(await _storageService!.isUserIdsStorageSupported())) {
          // The storage service doesn't exist or we don't support the user ids storage
          return null;
        }

        if (!(await _tryToLogInFromUsersInMemory(storageService: _storageService!))) {
          // Failed to log user from memory (this may happen if there are no ids in memory)
          return null;
        }

        final tokens = _getTokensFromTbClient();
        if (tokens == null) {
          appLogger()
              .e("We try to log in from user ids, it succeeds but there is no value stored in "
                  "tb client (which can't happen)");
          return null;
        }

        return tokens;
      }, testResult: (result) => result != null ? AuthStatus.signedIn : AuthStatus.sessionExpired);

  /// To call in order to the set the [AuthStatus] and send an event to the [AuthStatus] stream
  void _setAuthStatus(AuthStatus value) {
    if (value == _authStatus) {
      // Nothing to do
      return;
    }

    _logsHelper.d("New auth value: $value");
    _authStatus = value;
    _authStatusCtrl.add(value);
  }

  /// Try to sign in the user from the tokens returned by [loadTokens] method
  ///
  /// Return true if no problem occurred
  Future<bool> _tryToLogInFromTokens({
    required FutureOr<AuthTokens?> Function() loadTokens,
  }) async {
    final tokens = await loadTokens();
    if (tokens == null) {
      // We can't log the user, there is no tokens to use
      return false;
    }

    String? validToken;
    String? validRefreshToken;
    if (tokens.accessToken != null && tokens.accessToken!.isValid) {
      validToken = tokens.accessToken!.raw;
    }

    if (tokens.refreshToken != null && tokens.refreshToken!.isValid) {
      validRefreshToken = tokens.refreshToken!.raw;
    }

    if (validToken == null && validRefreshToken == null) {
      // The tokens are not valid, nothing to do
      return false;
    }

    if (validToken != null) {
      // The token is valid no need to test refresh token
      return true;
    }

    // If we are here the refresh token can't be null
    final refreshedTokens = await _refreshToken(tokens.refreshToken!);

    // The token refreshing also update the stored Thingsboard tokens
    if (refreshedTokens == null) {
      return false;
    }

    return true;
  }

  /// Try to sign in the user from the user ids stored in memory
  ///
  /// Return true if no problem occurred
  Future<bool> _tryToLogInFromUsersInMemory({
    required MixinAuthStorageService storageService,
  }) async {
    if (!(await storageService.isUserIdsStorageSupported())) {
      // We don't support the user ids storage, we can't sign in from memory
      return false;
    }

    final userIds = await storageService.loadUserIds();
    if (userIds == null) {
      // No user ids in memory
      return false;
    }

    final signInResult =
        await _unSafeSignInUser(username: userIds.username, password: userIds.password);
    if (signInResult.status != AuthSignInStatus.done) {
      // If we failed to signIn user from memory, we clear the storage
      await storageService.clearUserIds();
      return false;
    }

    return true;
  }

  /// This method is called to refresh a token thanks to the given [refreshToken]
  ///
  /// Return the refreshed token and the token, or null if a problem occurred
  Future<AuthTokens?> _refreshToken(AuthToken refreshToken) async {
    final response = await _noAuthReqManager.request(
      (tbClient) async => tbClient.refreshJwtToken(refreshToken: refreshToken.raw),
    );

    if (response.status != RequestStatus.success) {
      _logsHelper.w("A problem occurred when tried to refresh the tb token");
      return null;
    }

    return _getTokensFromTbClient();
  }

  /// Get the tokens from the current [ThingsboardClient]
  ///
  /// Return null if a problem occurred
  AuthTokens? _getTokensFromTbClient() {
    final tbClient = _noAuthReqManager.tbClient;
    final accessStrToken = tbClient.getJwtToken();
    final refreshStrToken = tbClient.getRefreshToken();
    if (accessStrToken == null) {
      return null;
    }

    final authToken = AuthToken.fromJwtToken(accessStrToken);
    if (authToken == null) {
      return null;
    }

    AuthToken? refreshToken;
    if (refreshStrToken != null) {
      refreshToken = AuthToken.fromJwtToken(refreshStrToken);
      if (refreshToken == null) {
        // A problem occurred when parsing the refresh token
        return null;
      }
    }

    return AuthTokens(accessToken: authToken, refreshToken: refreshToken);
  }
}
