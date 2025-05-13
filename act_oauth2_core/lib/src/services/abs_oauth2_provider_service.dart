import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mutex/mutex.dart';

abstract class AbsOAuth2ProviderService extends AbsWithLifeCycle with MixinAuthService {
  static const redirectUrlSeparator = ":/";
  static const redirectUrlSuffix = "${redirectUrlSeparator}oauthredirect";

  late final FlutterAppAuth _appAuth;

  late final DefaultOAuth2Conf _conf;

  late final LogsHelper _logsHelper;

  final String _logsCategory;

  /// This stream controller sends event when the [AuthStatus] change
  final StreamController<AuthStatus> _authStatusCtrl;

  final Mutex _mutex;

  /// The current [AuthStatus]
  AuthStatus _authStatus;

  AuthTokens _authTokens;

  MixinAuthStorageService? _storageService;

  @override
  MixinAuthStorageService? get storageService => _storageService;

  @protected
  FlutterAppAuth get appAuth => _appAuth;

  @protected
  LogsHelper get logsHelper => _logsHelper;

  @override
  AuthStatus get authStatus => _authStatus;

  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

  AbsOAuth2ProviderService({required String logsCategory})
    : _authStatus = AuthStatus.signedOut,
      _authTokens = const AuthTokens(),
      _authStatusCtrl = StreamController.broadcast(),
      _logsCategory = logsCategory,
      _mutex = Mutex();

  Future<void> initProvider({
    required LogsHelper parentLogsHelper,
    required FlutterAppAuth appAuth,
  }) async {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);
    _appAuth = appAuth;

    return initLifeCycle();
  }

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _conf = await getDefaultOAuth2Conf();

    if (await isUserSigned()) {
      _authStatus = AuthStatus.signedIn;
    }
  }

  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {
    if (storageService == _storageService) {
      // Nothing to do
      return;
    }

    _storageService = storageService;

    if (storageService == null) {
      // Nothing more to do
      return;
    }

    await _loadAndSetTokensFromMemoryIfRelevant(storageService);
  }

  Future<void> _loadAndSetTokensFromMemoryIfRelevant(MixinAuthStorageService storageService) async {
    final tokensFromMemory = await storageService.loadTokens();
    if (tokensFromMemory == null ||
        (tokensFromMemory.accessToken == null && tokensFromMemory.refreshToken == null)) {
      // Nothing to set
      return;
    }

    if (_authTokens.accessToken != null || _authTokens.refreshToken != null) {
      // We already have information in the app memory, we don't want to erase them with those which
      // are stored in cold memory.
      // But we also want to store the current one; therefore, we erase the cold memory with the
      // current.
      await storageService.storeTokens(tokens: _authTokens);
      return;
    }

    _authTokens = tokensFromMemory;
  }

  @protected
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf();

  @override
  Future<bool> isUserSigned() => _mutex.protect(() async {
    final isUserSigned =
        (_authTokens.accessToken?.isValid ?? false) || (_authTokens.refreshToken?.isValid ?? false);
    if (!isUserSigned) {
      // If the token and the refresh token are expired, we consider that we are signed out
      setAuthStatus(AuthStatus.signedOut);
    }

    return isUserSigned;
  });

  @override
  Future<AuthTokens?> getTokens() => _mutex.protect(() async {
    if (_authTokens.accessToken?.isValid ?? false) {
      return _authTokens;
    }

    if (_authTokens.refreshToken == null || !_authTokens.refreshToken!.isValid) {
      // There is no valid access and refresh token
      return null;
    }

    if (!(await _getTokenFromRefresh(refreshToken: _authTokens.refreshToken!.raw))) {
      return null;
    }

    return _authTokens;
  });

  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async =>
      crashUnimplemented("signInUser");

  @override
  Future<AuthSignInResult> redirectToExternalUserSignIn() => _mutex.protect(() async {
    final redirectUrl = await buildRedirectUrl();
    AuthSignInStatus? errorStatus;
    AuthorizationTokenResponse? response;
    try {
      response = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _conf.clientId,
          redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
          scopes: _conf.scopes,
        ),
      );
    } on FlutterAppAuthUserCancelledException catch (error) {
      // Handle user cancellation
      errorStatus = AuthSignInStatus.sessionExpired;
      logsHelper.i("User has cancelled the OAuth2 authentication");
    } catch (error) {
      errorStatus = AuthSignInStatus.genericError;
      logsHelper.e("An error occurred when tried to sign in the user: $error");
    }

    if (errorStatus != null) {
      return AuthSignInResult(status: errorStatus);
    }

    if (!await _parseTokenResponseAndRefreshTokenIfNeeded(response!)) {
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    setAuthStatus(AuthStatus.signedIn);
    return AuthSignInResult(status: AuthSignInStatus.done, extra: _authTokens);
  });

  @override
  Future<bool> signOut() => _mutex.protect(() async {
    final redirectUrl = await buildPostLogoutRedirectUrl();
    var result = false;
    try {
      await appAuth.endSession(
        EndSessionRequest(
          idTokenHint: _authTokens.idToken,
          postLogoutRedirectUrl: redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
        ),
      );
      result = true;
    } catch (error) {
      logsHelper.e("An error occurred when tried to sign out the user");
    }

    if (!result) {
      return false;
    }

    // Clean the auth info
    await _setOAuthTokens(null);

    setAuthStatus(AuthStatus.signedOut);

    return true;
  });

  /// To call in order to the set the [AuthStatus] and send an event to the [AuthStatus] stream
  @protected
  void setAuthStatus(AuthStatus value) {
    if (value == _authStatus) {
      // Nothing to do
      return;
    }

    _logsHelper.d("New auth value: $value");
    _authStatus = value;
    _authStatusCtrl.add(value);
  }

  @protected
  Future<String> buildRedirectUrl() async => "${_conf.appAuthRedirectScheme}$redirectUrlSuffix";

  @protected
  Future<String> buildPostLogoutRedirectUrl() async =>
      "${_conf.appAuthRedirectScheme}$redirectUrlSeparator";

  Future<void> _setOAuthTokens(AuthTokens? newTokens) async {
    if (_authTokens == newTokens) {
      // Nothing to do
      return;
    }

    if (newTokens == null) {
      _authTokens = const AuthTokens();
      await _storageService?.clearTokens();
      return;
    }

    _authTokens = newTokens;
    await _storageService?.storeTokens(tokens: newTokens);
  }

  Future<bool> _getTokenFromRefresh({required String refreshToken}) async {
    final response = await _getTokenResponseFromRefresh(refreshToken: refreshToken);
    if (response == null) {
      return false;
    }

    return _parseTokenResponse(response);
  }

  Future<TokenResponse?> _getTokenResponseFromRefresh({required String refreshToken}) async {
    final redirectUrl = await buildRedirectUrl();
    TokenResponse? response;
    try {
      response = await appAuth.token(
        TokenRequest(
          _conf.clientId,
          redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
          refreshToken: refreshToken,
          scopes: _conf.scopes,
        ),
      );
    } catch (error) {
      logsHelper.e("An error occurred when tried to get a token from the refresh token: $error");
    }

    return response;
  }

  Future<bool> _parseTokenResponseAndRefreshTokenIfNeeded(TokenResponse response) async {
    TokenResponse? tmpResponse = response;
    if (response.accessToken == null && response.refreshToken != null) {
      appLogger().d(
        "We receive a refresh token and no access token. We use the refresh token to "
        "get the access",
      );

      tmpResponse = await _getTokenResponseFromRefresh(refreshToken: response.refreshToken!);
      if (tmpResponse == null) {
        return false;
      }
    }

    return _parseTokenResponse(tmpResponse);
  }

  Future<bool> _parseTokenResponse(TokenResponse response) async {
    final newTokens = _authTokens.copyWith(
      accessToken: AuthToken(
        raw: response.accessToken!,
        expiration: response.accessTokenExpirationDateTime,
      ),
      refreshToken: (response.refreshToken != null) ? AuthToken(raw: response.refreshToken!) : null,
      idToken: response.idToken,
    );
    await _setOAuthTokens(newTokens);

    return true;
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _authStatusCtrl.close();
    return super.disposeLifeCycle();
  }
}
