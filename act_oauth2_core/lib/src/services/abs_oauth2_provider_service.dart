// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mutex/mutex.dart';

/// This is an abstract class to define an OAuth2 provider service to use for authentication
abstract class AbsOAuth2ProviderService extends AbsWithLifeCycle with MixinAuthService {
  /// This is the separator used in the redirect scheme for separating the app part and OAuth suffix
  static const redirectUrlSeparator = ":/";

  /// This is the suffix to use in the redirection url
  static const redirectUrlSuffix = "${redirectUrlSeparator}oauthredirect";

  /// This is the [FlutterAppAuth] to use for this OAuth2 provider
  late final FlutterAppAuth _appAuth;

  /// This is the default OAuth2 config linked to the provider
  late final DefaultOAuth2Conf _conf;

  /// This is the logs helper linked to the provider
  late final LogsHelper _logsHelper;

  /// This is the logs category to use with the provider
  final String _logsCategory;

  /// This stream controller sends event when the [AuthStatus] change
  final StreamController<AuthStatus> _authStatusCtrl;

  /// The mutex is used to prevent multiple token getting at the same time
  final Mutex _mutex;

  /// The current [AuthStatus]
  AuthStatus _authStatus;

  /// Contains the current auth tokens
  AuthTokens _authTokens;

  /// This represents the storage service linked to the auth service
  MixinAuthStorageService? _storageService;

  /// {@macro act_shared_auth.MixinAuthService.storageService}
  @override
  MixinAuthStorageService? get storageService => _storageService;

  /// Getter of the flutter app auth service
  @protected
  FlutterAppAuth get appAuth => _appAuth;

  /// Getter of the logs helper
  @protected
  LogsHelper get logsHelper => _logsHelper;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

  /// Class constructor
  AbsOAuth2ProviderService({required String logsCategory})
    : _authStatus = AuthStatus.signedOut,
      _authTokens = const AuthTokens(),
      _authStatusCtrl = StreamController.broadcast(),
      _logsCategory = logsCategory,
      _mutex = Mutex();

  /// Initialize the provider.
  ///
  /// This method already calls [initLifeCycle]; therefore, don't call [initLifeCycle] but this
  /// method.
  Future<void> initProvider({
    required LogsHelper parentLogsHelper,
    required FlutterAppAuth appAuth,
  }) async {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);
    _appAuth = appAuth;

    return initLifeCycle();
  }

  /// Init the service
  ///
  /// DON'T CALL THIS METHOD, CALL [initProvider] INSTEAD
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _conf = await getDefaultOAuth2Conf();

    if (await isUserSigned()) {
      _authStatus = AuthStatus.signedIn;
    }
  }

  /// {@template act_oauth2_google.AbsOAuth2ProviderService.getDefaultOAuth2Conf}
  /// Get the OAuth2 configuration to use with this provider
  /// {@endtemplate}
  @protected
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf();

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
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

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async =>
      crashUnimplemented("signInUser");

  /// {@macro act_shared_auth.MixinAuthService.redirectToExternalUserSignIn}
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
    } on FlutterAppAuthUserCancelledException catch (_) {
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

  /// {@macro act_shared_auth.MixinAuthService.signOut}
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

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() => _mutex.protect(() async {
    final isUserSigned =
        (_authTokens.accessToken?.isValid() ?? false) ||
        (_authTokens.refreshToken?.isValid() ?? false);
    if (!isUserSigned) {
      // If the token and the refresh token are expired, we consider that we are signed out
      setAuthStatus(AuthStatus.signedOut);
    }

    return isUserSigned;
  });

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() => _mutex.protect(() async {
    if (_authTokens.accessToken?.isValid() ?? false) {
      return _authTokens;
    }

    if (_authTokens.refreshToken == null || !_authTokens.refreshToken!.isValid()) {
      // There is no valid access and refresh token
      return null;
    }

    if (!(await _getTokenFromRefresh(refreshToken: _authTokens.refreshToken!.raw))) {
      return null;
    }

    return _authTokens;
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

  /// Build the URL used by the provider to redirect to the app after a sign in
  @protected
  Future<String> buildRedirectUrl() async => "${_conf.appAuthRedirectScheme}$redirectUrlSuffix";

  /// Build the URL used by the provider to redirect to the app after a sign out
  @protected
  Future<String> buildPostLogoutRedirectUrl() async =>
      "${_conf.appAuthRedirectScheme}$redirectUrlSeparator";

  /// The method loads the token from memory and set the local [_authTokens].
  ///
  /// Because the storage service can be set in the service life (and not only at start), the
  /// method also checks if the [_authTokens] aren't null and in that case, it will erase the
  /// tokens in memory (to avoid to have wrong tokens stored in memory).
  Future<void> _loadAndSetTokensFromMemoryIfRelevant(MixinAuthStorageService storageService) async {
    final tokensFromMemory = await storageService.loadTokens();
    if (tokensFromMemory == null ||
        (tokensFromMemory.accessToken == null && tokensFromMemory.refreshToken == null)) {
      // Nothing to set
      return;
    }

    if (tokensFromMemory != _authTokens &&
        (_authTokens.accessToken != null || _authTokens.refreshToken != null)) {
      // We already have information in the app memory, we don't want to erase them with those which
      // are stored in cold memory.
      // But we also want to store the current one; therefore, we erase the cold memory with the
      // current.
      await storageService.storeTokens(tokens: _authTokens);
      return;
    }

    _authTokens = tokensFromMemory;
  }

  /// Set the OAuth2 tokens
  ///
  /// If [newTokens] is null, we also clear the memory
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

  /// Get the token from the provider thanks to the given [refreshToken].
  ///
  /// The method sets the token got to the [_authTokens] member.
  ///
  /// Return true if no problem occurred.
  Future<bool> _getTokenFromRefresh({required String refreshToken}) async {
    final response = await _getTokenResponseFromRefresh(refreshToken: refreshToken);
    if (response == null) {
      return false;
    }

    return _parseTokenResponse(response);
  }

  /// Get the token response from the provider thanks to the given [refreshToken]
  ///
  /// Return null if a problem occurred.
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

  /// Parse the [response] and ask a token thanks to the refresh token, if needed. Also sets the
  /// token to the [_authTokens] member.
  ///
  /// Return true if no problem occurred.
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

  /// Parse the [response] and sets the token to the [_authTokens] member.
  ///
  /// Return true if no problem occurred.
  Future<bool> _parseTokenResponse(TokenResponse response) async {
    if (response.accessToken == null) {
      appLogger().w("The access token is null, we can't parse the token response");
      return false;
    }

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

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _authStatusCtrl.close();
    return super.disposeLifeCycle();
  }
}
