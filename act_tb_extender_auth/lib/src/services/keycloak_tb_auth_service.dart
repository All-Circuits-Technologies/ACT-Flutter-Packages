// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_tb_extender_auth/src/clients/tb_extender_broker_client.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_response.dart';
import 'package:act_tb_extender_auth/src/models/broker_login_result.dart';
import 'package:act_tb_extender_auth/src/models/broker_user.dart';
import 'package:act_tb_extender_auth/src/types/broker_auth_error.dart';
import 'package:mutex/mutex.dart';

/// Signature of the function which refreshes the ThingsBoard tokens against ThingsBoard itself.
///
/// It receives the raw ThingsBoard refresh token and answers the refreshed [AuthTokens], or null
/// when ThingsBoard refused that refresh token.
typedef TbTokenRefresher = Future<AuthTokens?> Function(String tbRefreshToken);

/// Signature of the function which loads the Keycloak configuration the service reads to decide
/// whether the plain http fallback of a development stack has to be engaged.
typedef KeycloakConfLoader = DefaultOAuth2Conf? Function();

/// Signature of the function an application is told a session ended with.
///
/// Whatever an application holds which belongs to the account which is leaving, a paired device,
/// a cache or a route, is forgotten there: this package knows of none of it.
typedef OnSignOut = Future<void> Function();

/// The authentication service of an application whose users sign in with Keycloak and whose data
/// lives in ThingsBoard.
///
/// ThingsBoard validates no token but its own; therefore, the Keycloak access token is exchanged
/// at the tb-extender broker, which provisions the customer user and answers a pair of ThingsBoard
/// tokens.
///
/// ## Two sets of tokens
///
/// The tokens [getTokens] answers are the ThingsBoard ones, which is what the rest of an
/// application signs its calls with, and they are kept by the storage service the authentication
/// manager sets. The Keycloak ones are held by the Keycloak provider, and kept by the storage
/// which is handed to it, under another key: they are only ever read to call the broker and to
/// read the claims [getIdpAccessToken] hands out.
///
/// ## Sign in and refresh
///
///  - [redirectToExternalUserSignIn] runs the Keycloak PKCE flow, then exchanges its access token
///    at the broker.
///  - [getTokens] climbs a ladder of four steps: the cached ThingsBoard access token, a refresh
///    against ThingsBoard, a Keycloak refresh followed by a new broker login, and finally an
///    expired session.
///  - [signOut] ends the Keycloak session and drops both sets of tokens.
///  - [acceptTerms] writes the version of the terms the user accepted on the Keycloak account,
///    through the broker, then refreshes the Keycloak tokens so that the claim follows.
///
/// Every collaborator is given to the constructor, so this class reaches no service locator;
/// `KeycloakTbAuthServiceBuilder` is what assembles the ones an application runs with.
class KeycloakTbAuthService extends AbsWithLifeCycle
    with MixinAuthService, MixinRawIdpTokenProvider, MixinTermsAcceptor {
  /// This is the logs category linked to the auth service
  static const _logsCategory = "keycloakTbAuth";

  /// The Keycloak provider, which runs the PKCE flow and owns the Keycloak tokens
  final AbsOAuth2ProviderService _provider;

  /// The client of the broker the Keycloak tokens are exchanged at
  final TbExtenderBrokerClient _brokerClient;

  /// The storage the [_provider] keeps the Keycloak tokens in, distinct from the ThingsBoard one
  final MixinAuthStorageService _keycloakStorageService;

  /// The function which refreshes the ThingsBoard tokens against ThingsBoard itself
  final TbTokenRefresher _tbTokenRefresher;

  /// The function which loads the Keycloak configuration read at init
  final KeycloakConfLoader _keycloakConfLoader;

  /// The library which speaks OAuth 2.0, the [_provider] is initialized with
  final FlutterAppAuth _appAuth;

  /// The function which tells the application that a session ended, if it asked to be told
  final OnSignOut? _onSignOut;

  /// The controller of the authentication status stream
  final StreamController<AuthStatus> _authStatusCtrl;

  /// The mutex which guards the public entry points against the concurrent calls
  final Mutex _mutex;

  /// The logs helper linked to the service
  final LogsHelper _logsHelper;

  /// The current authentication status
  AuthStatus _authStatus;

  /// The ThingsBoard tokens held in memory, which [_storageService] mirrors
  AuthTokens? _tbTokens;

  /// The user the broker named at the last login
  BrokerUser? _brokerUser;

  /// The storage the ThingsBoard tokens are kept in, which the authentication manager sets
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
  ///
  /// [keycloakProvider] runs the PKCE flow, [brokerClient] speaks to the broker,
  /// [keycloakStorageService] is where the Keycloak tokens are kept, [tbTokenRefresher] refreshes
  /// the ThingsBoard ones and [keycloakConfLoader] answers the Keycloak configuration.
  ///
  /// [appAuth] defaults to a plain [FlutterAppAuth], and [onSignOut] is what an application is
  /// told a session ended with.
  KeycloakTbAuthService({
    required AbsOAuth2ProviderService keycloakProvider,
    required TbExtenderBrokerClient brokerClient,
    required MixinAuthStorageService keycloakStorageService,
    required TbTokenRefresher tbTokenRefresher,
    required KeycloakConfLoader keycloakConfLoader,
    FlutterAppAuth? appAuth,
    OnSignOut? onSignOut,
  }) : _provider = keycloakProvider,
       _brokerClient = brokerClient,
       _keycloakStorageService = keycloakStorageService,
       _tbTokenRefresher = tbTokenRefresher,
       _keycloakConfLoader = keycloakConfLoader,
       _appAuth = appAuth ?? const FlutterAppAuth(),
       _onSignOut = onSignOut,
       _authStatus = AuthStatus.signedOut,
       _authStatusCtrl = StreamController<AuthStatus>.broadcast(),
       _mutex = Mutex(),
       _logsHelper = LogsHelper(category: _logsCategory);

  /// Init the service, which hands the provider the storage of the Keycloak tokens and the library
  /// it speaks OAuth 2.0 with.
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await _provider.setStorageService(_keycloakStorageService);
    await _provider.initProvider(parentLogsHelper: _logsHelper, appAuth: _resolveAppAuth());

    if (_hasUsableTbTokens()) {
      _setAuthStatus(AuthStatus.signedIn);
    }
  }

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {
    _storageService = storageService;

    if (storageService == null) {
      return;
    }

    // Read the ThingsBoard tokens a previous run left behind.
    _tbTokens = await storageService.loadTokens();

    if (_hasUsableTbTokens()) {
      _setAuthStatus(AuthStatus.signedIn);
    }
  }

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  ///
  /// This service only signs a user in through Keycloak: there is no username and no password to
  /// give it, and [redirectToExternalUserSignIn] is what an application calls instead.
  @override
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  }) async {
    _logsHelper.w("signInUser isn't supported by this service, call redirectToExternalUserSignIn "
        "instead");

    return const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
  }

  /// {@macro act_shared_auth.MixinAuthService.redirectToExternalUserSignIn}
  ///
  /// Runs the Keycloak PKCE flow, then exchanges the Keycloak access token at the broker.
  @override
  Future<AuthSignInResult> redirectToExternalUserSignIn() =>
      _mutex.protect(_unsafeRedirectToExternalUserSignIn);

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() => _mutex.protect(_unsafeGetTokens);

  /// {@macro act_shared_auth.MixinRawIdpTokenProvider.getIdpAccessToken}
  ///
  /// [getTokens] answers the ThingsBoard tokens, which is what the rest of an application talks
  /// with. This one is the Keycloak token, which only what Keycloak itself owns needs: the
  /// deletion of an account, and the claims an application reads, such as the date its terms were
  /// accepted on.
  @override
  Future<String?> getIdpAccessToken() async {
    final tokens = await _provider.getTokens();
    final accessToken = tokens?.accessToken;

    return (accessToken?.isValid() ?? false) ? accessToken!.raw : null;
  }

  /// {@macro act_shared_auth.MixinTermsAcceptor.acceptTerms}
  ///
  /// The broker writes the version on the Keycloak account, then the Keycloak tokens are
  /// refreshed so that the claim in hand says the same. A refresh which fails isn't an error:
  /// the account is right, and the next refresh will carry the claim.
  @override
  Future<bool> acceptTerms({required String version}) => _mutex.protect(() async {
    final kcAccessToken = await _validKeycloakAccessToken();
    if (kcAccessToken == null) {
      _logsHelper.w("No valid Keycloak session in hand, the terms can't be recorded");
      return false;
    }

    final error = await _brokerClient.acceptTerms(kcAccessToken, version: version);
    if (error != null) {
      _logsHelper.w("The broker didn't record the terms acceptance: $error");
      return false;
    }

    if (!await _provider.refreshTokens()) {
      _logsHelper.i("The terms are recorded but the tokens couldn't be refreshed yet, the claim "
          "will follow at the next refresh");
    }

    return true;
  });

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() => _mutex.protect(() async {
    try {
      await _provider.signOut();
    } catch (error) {
      _logsHelper.w("An error occurred when ending the Keycloak session: $error");
    }

    _tbTokens = null;
    _brokerUser = null;
    await _storageService?.clearTokens();

    // Whatever the application holds which belongs to the account which is leaving is forgotten
    // here, and it is the application which knows what that is.
    await _onSignOut?.call();

    _setAuthStatus(AuthStatus.signedOut);

    return true;
  });

  /// {@macro act_shared_auth.MixinAuthService.deleteAccount}
  ///
  /// Erases the account behind the current Keycloak session, the ThingsBoard customer, the
  /// telemetry of its devices and the Keycloak identity, then signs the user out.
  ///
  /// The sign out is deliberately outside of the protected section: [signOut] takes the same
  /// mutex, and it only runs once the account is actually gone, at which point the tokens in hand
  /// point at nothing.
  @override
  Future<AuthDeleteResult> deleteAccount() async {
    final error = await _mutex.protect(_unsafeDeleteAccount);

    if (error == null) {
      await signOut();
      return const AuthDeleteResult(status: AuthDeleteStatus.done);
    }

    return AuthDeleteResult(
      status: (error == BrokerAuthError.network)
          ? AuthDeleteStatus.networkError
          : AuthDeleteStatus.genericError,
      extra: error,
    );
  }

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() => _mutex.protect(() async => _hasUsableTbTokens());

  /// {@macro act_shared_auth.MixinAuthService.getCurrentUserId}
  @override
  Future<String?> getCurrentUserId() async => _brokerUser?.tbUserId;

  /// {@macro act_shared_auth.MixinAuthService.getEmailAddress}
  @override
  Future<String?> getEmailAddress() async => _brokerUser?.email;

  /// Answer the library the provider speaks OAuth 2.0 with.
  ///
  /// A Keycloak configuration which is served over plain http is a local development stack, and
  /// the native library refuses it unless it is told to allow the insecure connections; therefore,
  /// [_appAuth] is wrapped in an [InsecureDevAppAuth] for that case only. A realm served over
  /// https, and a configuration which can't be read at all, are handed the library untouched.
  FlutterAppAuth _resolveAppAuth() {
    final conf = _keycloakConfLoader();
    if (conf != null && shouldAllowInsecureAppAuthConnections(conf)) {
      _logsHelper.w("The Keycloak configuration names a plain http endpoint: the insecure "
          "connections are allowed, which is meant for a local development stack only and must "
          "never happen against a https realm");

      return InsecureDevAppAuth(_appAuth);
    }

    return _appAuth;
  }

  /// Ask the broker to erase the account, without the protection of the mutex.
  ///
  /// Return null when the account is gone, or the error which stopped the deletion.
  Future<BrokerAuthError?> _unsafeDeleteAccount() async {
    final kcAccessToken = await _validKeycloakAccessToken();
    if (kcAccessToken == null) {
      _logsHelper.w("No valid Keycloak session in hand, the account can't be deleted");
      return BrokerAuthError.invalidToken;
    }

    return _brokerClient.deleteAccount(kcAccessToken);
  }

  /// Run the sign in flow without the protection of the mutex.
  Future<AuthSignInResult> _unsafeRedirectToExternalUserSignIn() async {
    final providerResult = await _provider.redirectToExternalUserSignIn();
    if (providerResult.status != AuthSignInStatus.done) {
      // A cancellation and an error of the provider are answered as they are.
      return providerResult;
    }

    final kcAccessToken = await _validKeycloakAccessToken();
    if (kcAccessToken == null) {
      _logsHelper.w("The Keycloak sign in succeeded but answered no valid access token");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    final loginResult = await _brokerClient.login(kcAccessToken);
    switch (loginResult) {
      case BrokerLoginSuccess(:final response):
        await _applyBrokerSuccess(response);
        _setAuthStatus(AuthStatus.signedIn);
        return AuthSignInResult(status: AuthSignInStatus.done, extra: response.user);
      case BrokerLoginFailure():
        _logsHelper.w("The broker login failed during the sign in: ${loginResult.error}");
        return AuthSignInResult(
          status: (loginResult.error == BrokerAuthError.network)
              ? AuthSignInStatus.networkError
              : AuthSignInStatus.genericError,
          extra: loginResult,
        );
    }
  }

  /// Get valid ThingsBoard tokens without the protection of the mutex, climbing the four steps of
  /// the refresh ladder.
  Future<AuthTokens?> _unsafeGetTokens() async {
    // 1. A ThingsBoard access token which is still valid is answered as it is.
    final current = _tbTokens;
    if (current?.accessToken?.isValid() ?? false) {
      return current;
    }

    // 2. The refresh is asked of ThingsBoard itself, with the ThingsBoard refresh token.
    final tbRefreshToken = current?.refreshToken;
    if (tbRefreshToken != null && tbRefreshToken.isValid()) {
      final refreshed = await _tbTokenRefresher(tbRefreshToken.raw);
      if (refreshed?.accessToken?.isValid() ?? false) {
        _tbTokens = refreshed;
        await _storageService?.storeTokens(tokens: refreshed!);
        _setAuthStatus(AuthStatus.signedIn);
        return refreshed;
      }

      _logsHelper.i("The ThingsBoard refresh failed, falling back to the Keycloak one");
    }

    // 3. The Keycloak token is refreshed, and the broker is called again: it holds no state, so
    //    the call is the very same one the sign in made.
    final kcAccessToken = await _validKeycloakAccessToken();
    if (kcAccessToken != null) {
      final loginResult = await _brokerClient.login(kcAccessToken);
      if (loginResult is BrokerLoginSuccess) {
        final tokens = await _applyBrokerSuccess(loginResult.response);
        _setAuthStatus(AuthStatus.signedIn);
        return tokens;
      }

      _logsHelper.w("The broker login failed after the Keycloak refresh");
    }

    // 4. Nothing is left to refresh with, the session has expired.
    _setAuthStatus(AuthStatus.sessionExpired);

    return null;
  }

  /// Get the raw Keycloak access token of the provider, refreshed when it needed to be.
  ///
  /// Return null when the Keycloak session is gone.
  Future<String?> _validKeycloakAccessToken() async {
    final kcTokens = await _provider.getTokens();
    final accessToken = kcTokens?.accessToken;

    return (accessToken != null && accessToken.isValid()) ? accessToken.raw : null;
  }

  /// Build the [AuthTokens] out of a [response] of the broker, keep them and remember the user.
  Future<AuthTokens> _applyBrokerSuccess(BrokerLoginResponse response) async {
    final accessToken =
        AuthToken.fromJwtToken(response.tbToken) ??
        AuthToken(
          raw: response.tbToken,
          expiration: DateTime.now().toUtc().add(Duration(seconds: response.expiresIn)),
        );
    final refreshToken =
        AuthToken.fromJwtToken(response.tbRefreshToken) ?? AuthToken(raw: response.tbRefreshToken);

    final tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
    _tbTokens = tokens;
    _brokerUser = response.user;
    await _storageService?.storeTokens(tokens: tokens);

    return tokens;
  }

  /// Say whether the ThingsBoard tokens held in memory are usable, which one valid token of the
  /// two is enough for.
  bool _hasUsableTbTokens() {
    final tokens = _tbTokens;
    if (tokens == null) {
      return false;
    }

    return (tokens.accessToken?.isValid() ?? false) || (tokens.refreshToken?.isValid() ?? false);
  }

  /// Set the [AuthStatus] and tell the stream when it changed.
  void _setAuthStatus(AuthStatus value) {
    if (value == _authStatus) {
      // Nothing to do
      return;
    }

    _logsHelper.d("New auth value: $value");
    _authStatus = value;
    _authStatusCtrl.add(value);
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _provider.disposeLifeCycle();
    _brokerClient.close();
    await _authStatusCtrl.close();

    return super.disposeLifeCycle();
  }
}
