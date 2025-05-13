import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/src/managers/tb_no_auth_server_req_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

class TbStdAuthService extends AbsWithLifeCycle with MixinAuthService {
  static const _logsCategory = "tbAuth";

  final StreamController<AuthStatus> _authStatusCtrl;

  late final TbNoAuthServerReqManager _noAuthReqManager;

  final Mutex _mutex;

  final LogsHelper _logsHelper;

  AuthStatus _authStatus;

  MixinAuthStorageService? _storageService;

  @override
  MixinAuthStorageService? get storageService => _storageService;

  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

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

  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async =>
      _storageService = storageService;

  @override
  Future<bool> isUserSigned() => _mutex.protect(() async => _authStatus == AuthStatus.signedIn);

  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) =>
      _mutex.protect(() async => _unSafeSignInUser(username: username, password: password));

  @override
  Future<AuthTokens?> getTokens() => _mutex.protect(() async => _unSafeGetTokens(
        initTokensLoading: _getTokensFromTbClient,
      ));

  @override
  Future<bool> signOut() => _mutex.protect(() async {
        await _noAuthReqManager.tbClient.logout();
        await _storageService?.clearUserIds();

        _setAuthStatus(AuthStatus.signedOut);

        return true;
      });

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
