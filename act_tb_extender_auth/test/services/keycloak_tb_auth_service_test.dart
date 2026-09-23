// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

/// The user the broker names beside the tokens it answers.
const _user = BrokerUser(
  tbUserId: "user-id",
  customerId: "customer-id",
  email: "ada@example.test",
);

/// A success payload of the broker which names that user.
const _successResponse = BrokerLoginResponse(
  tbToken: "tb-access",
  tbRefreshToken: "tb-refresh",
  expiresIn: 3600,
  user: _user,
);

/// A token which never expires.
AuthToken _validToken(String raw) => AuthToken(raw: raw);

/// A token which expired an hour ago.
AuthToken _expiredToken(String raw) =>
    AuthToken(raw: raw, expiration: DateTime.now().toUtc().subtract(const Duration(hours: 1)));

/// The Keycloak configuration of an application whose realm is served over [issuer].
DefaultOAuth2Conf _conf(String? issuer) => DefaultOAuth2Conf(
  clientId: "a-client-id",
  issuer: issuer,
  discoveryUrl: null,
  providerUrlConf: null,
  scopes: const ["openid"],
  appAuthRedirectScheme: "com.example.app",
);

void main() {
  late FakeGlobalManager globalManager;
  late FakeKeycloakProvider provider;
  late FakeBrokerClient broker;
  late FakeAuthStorage storage;
  late FakeAuthStorage keycloakStorage;
  late RecordingTbRefresher refresher;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    provider = FakeKeycloakProvider();
    broker = FakeBrokerClient();
    storage = FakeAuthStorage();
    keycloakStorage = FakeAuthStorage();
    refresher = RecordingTbRefresher();
  });

  tearDown(() => globalManager.reset());

  /// The service of an application whose Keycloak realm is served over [issuer], and which is told
  /// a session ended through [onSignOut].
  KeycloakTbAuthService aService({
    String? issuer = "https://keycloak.example.test/realms/a-realm",
    OnSignOut? onSignOut,
    FlutterAppAuth? appAuth,
  }) => KeycloakTbAuthService(
    keycloakProvider: provider,
    brokerClient: broker,
    keycloakStorageService: keycloakStorage,
    tbTokenRefresher: refresher.call,
    keycloakConfLoader: () => (issuer == null) ? null : _conf(issuer),
    appAuth: appAuth,
    onSignOut: onSignOut,
  );

  /// The same service, holding the ThingsBoard tokens of a previous run.
  Future<KeycloakTbAuthService> aSignedInService({AuthTokens? tokens, OnSignOut? onSignOut}) async {
    storage.stored = tokens;

    final service = aService(onSignOut: onSignOut);
    await service.setStorageService(storage);

    return service;
  }

  group("KeycloakTbAuthService.initLifeCycle", () {
    test("hands the provider the storage the Keycloak tokens are kept in", () async {
      final service = aService();

      await service.initLifeCycle();

      expect(provider.receivedStorage, same(keycloakStorage));
    });

    test("allows the insecure connections for a realm served over plain http", () async {
      const baseAppAuth = FlutterAppAuth();
      final service = aService(issuer: "http://10.0.0.1:8081/realms/a-realm", appAuth: baseAppAuth);

      await service.initLifeCycle();

      expect(provider.receivedAppAuth, isA<InsecureDevAppAuth>());
    });

    test("hands the library untouched for a realm served over https", () async {
      const baseAppAuth = FlutterAppAuth();
      final service = aService(appAuth: baseAppAuth);

      await service.initLifeCycle();

      expect(provider.receivedAppAuth, same(baseAppAuth));
    });

    test("hands the library untouched when no Keycloak configuration can be read", () async {
      const baseAppAuth = FlutterAppAuth();
      final service = aService(issuer: null, appAuth: baseAppAuth);

      await service.initLifeCycle();

      expect(provider.receivedAppAuth, same(baseAppAuth));
    });
  });

  group("KeycloakTbAuthService.signInUser", () {
    test("answers that it isn't supported rather than crashing", () async {
      final result = await aService().signInUser(username: "u", password: "p");

      expect(result.status, AuthSignInStatus.notSupportedYet);
    });
  });

  group("KeycloakTbAuthService.redirectToExternalUserSignIn", () {
    test("runs the Keycloak flow, exchanges at the broker and signs the user in", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.onLogin = (_) => const BrokerLoginSuccess(_successResponse);
      final service = await aSignedInService();

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.done);
      expect(result.extra, _user);
      expect(service.authStatus, AuthStatus.signedIn);
      expect(broker.lastToken, "kc-access");
      expect(storage.stored?.accessToken?.raw, "tb-access");
      expect(storage.stored?.refreshToken?.raw, "tb-refresh");
      expect(await service.getCurrentUserId(), "user-id");
      expect(await service.getEmailAddress(), "ada@example.test");
    });

    test("answers a cancellation of the provider without calling the broker", () async {
      provider.redirectResult = const AuthSignInResult(status: AuthSignInStatus.sessionExpired);

      final result = await aService().redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.sessionExpired);
      expect(broker.loginCallCount, 0);
    });

    test("reads a broker which couldn't be reached as a network error", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.onLogin = (_) => const BrokerLoginFailure(BrokerAuthError.network);
      final service = aService();

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.networkError);
      expect(service.authStatus, AuthStatus.signedOut);
      expect(provider.signOutCalled, isTrue);
    });

    test("reads a broker which refused the account as a generic error carrying it", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.onLogin = (_) =>
          const BrokerLoginFailure(BrokerAuthError.emailNotVerified, statusCode: 403);

      final result = await aService().redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.genericError);
      expect(result.extra, isA<BrokerLoginFailure>());
      expect(provider.signOutCalled, isTrue, reason: "the next attempt must ask the credentials");
    });
  });

  group("KeycloakTbAuthService.getTokens", () {
    test("answers the cached ThingsBoard token without refreshing anything", () async {
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _validToken("cached-access"),
          refreshToken: _validToken("cached-refresh"),
        ),
      );

      final tokens = await service.getTokens();

      expect(tokens?.accessToken?.raw, "cached-access");
      expect(refresher.callCount, 0);
      expect(broker.loginCallCount, 0);
    });

    test("refreshes against ThingsBoard when the access token expired", () async {
      refresher.result = AuthTokens(
        accessToken: _validToken("fresh-access"),
        refreshToken: _validToken("fresh-refresh"),
      );
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _expiredToken("old-access"),
          refreshToken: _validToken("tb-refresh"),
        ),
      );

      final tokens = await service.getTokens();

      expect(tokens?.accessToken?.raw, "fresh-access");
      expect(refresher.lastRefreshToken, "tb-refresh");
      expect(broker.loginCallCount, 0);
      expect(service.authStatus, AuthStatus.signedIn);
      expect(storage.stored?.accessToken?.raw, "fresh-access");
    });

    test("falls back to the Keycloak refresh and a new broker login", () async {
      refresher.result = null;
      provider.tokens = AuthTokens(accessToken: _validToken("kc-fresh"));
      broker.onLogin = (_) => const BrokerLoginSuccess(_successResponse);
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _expiredToken("old-access"),
          refreshToken: _validToken("tb-refresh"),
        ),
      );

      final tokens = await service.getTokens();

      expect(tokens?.accessToken?.raw, "tb-access");
      expect(refresher.callCount, 1);
      expect(broker.lastToken, "kc-fresh");
      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("reports an expired session when the Keycloak refresh is dead too", () async {
      refresher.result = null;
      provider.tokens = null;
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _expiredToken("old-access"),
          refreshToken: _validToken("tb-refresh"),
        ),
      );

      final tokens = await service.getTokens();

      expect(tokens, isNull);
      expect(service.authStatus, AuthStatus.sessionExpired);
    });

    test("reports an expired session when the broker refuses the new login", () async {
      refresher.result = null;
      provider.tokens = AuthTokens(accessToken: _validToken("kc-fresh"));
      broker.onLogin = (_) => const BrokerLoginFailure(BrokerAuthError.thingsboardUnavailable);
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _expiredToken("old-access"),
          refreshToken: _validToken("tb-refresh"),
        ),
      );

      final tokens = await service.getTokens();

      expect(tokens, isNull);
      expect(service.authStatus, AuthStatus.sessionExpired);
    });
  });

  group("KeycloakTbAuthService.getIdpAccessToken", () {
    test("answers the raw Keycloak token of a signed in user", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));

      expect(await aService().getIdpAccessToken(), "kc-access");
    });

    test("answers nothing when the user is signed out", () async {
      provider.tokens = null;

      expect(await aService().getIdpAccessToken(), isNull);
    });

    test("answers nothing when the Keycloak token expired", () async {
      provider.tokens = AuthTokens(accessToken: _expiredToken("kc-access"));

      expect(await aService().getIdpAccessToken(), isNull);
    });
  });

  group("KeycloakTbAuthService.signOut", () {
    test("ends the Keycloak session, drops the ThingsBoard tokens and signs the user out",
        () async {
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _validToken("cached-access"),
          refreshToken: _validToken("cached-refresh"),
        ),
      );
      expect(await service.isUserSigned(), isTrue);

      final result = await service.signOut();

      expect(result, isTrue);
      expect(provider.signOutCalled, isTrue);
      expect(storage.stored, isNull);
      expect(service.authStatus, AuthStatus.signedOut);
      expect(await service.isUserSigned(), isFalse);
    });

    test("tells the application that the session of its user ended", () async {
      var told = 0;
      final service = await aSignedInService(onSignOut: () async => told++);

      await service.signOut();

      expect(told, 1);
    });

    test("signs the user out all the same when the application asked to be told nothing",
        () async {
      final service = await aSignedInService();

      expect(await service.signOut(), isTrue);
      expect(service.authStatus, AuthStatus.signedOut);
    });
  });

  group("KeycloakTbAuthService.deleteAccount", () {
    // The sign out takes the same mutex as the deletion; therefore, this test hangs rather
    // than fails should the service ever call it from inside the protected section.
    test("erases the account, then signs the user out outside of the mutex", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      var told = 0;
      final service = await aSignedInService(
        tokens: AuthTokens(
          accessToken: _validToken("cached-access"),
          refreshToken: _validToken("cached-refresh"),
        ),
        onSignOut: () async => told++,
      );

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.done);
      expect(broker.deleteCallCount, 1);
      expect(broker.lastToken, "kc-access");
      expect(provider.signOutCalled, isTrue);
      expect(storage.stored, isNull);
      expect(told, 1);
    });

    test("keeps the session when the broker refused the deletion", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.deleteError = BrokerAuthError.thingsboardUnavailable;
      final service = await aSignedInService();

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.genericError);
      expect(result.extra, BrokerAuthError.thingsboardUnavailable);
      expect(provider.signOutCalled, isFalse);
    });

    test("reads a broker which couldn't be reached as a network error", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.deleteError = BrokerAuthError.network;
      final service = await aSignedInService();

      expect((await service.deleteAccount()).status, AuthDeleteStatus.networkError);
    });

    test("doesn't call the broker without a Keycloak session in hand", () async {
      provider.tokens = null;
      final service = await aSignedInService();

      final result = await service.deleteAccount();

      expect(result.status, AuthDeleteStatus.genericError);
      expect(broker.deleteCallCount, 0);
      expect(provider.signOutCalled, isFalse);
    });
  });

  group("KeycloakTbAuthService.acceptTerms", () {
    test("hands the version to the broker and refreshes the Keycloak tokens", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      final service = await aSignedInService();

      expect(await service.acceptTerms(version: "2026-09-16"), isTrue);
      expect(broker.lastToken, "kc-access");
      expect(broker.lastAcceptedVersion, "2026-09-16");
      expect(provider.refreshCalls, 1);
    });

    test("answers false and refreshes nothing when the broker refused", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      broker.acceptTermsError = BrokerAuthError.keycloakUnavailable;
      final service = await aSignedInService();

      expect(await service.acceptTerms(version: "2026-09-16"), isFalse);
      expect(provider.refreshCalls, 0);
    });

    test("doesn't call the broker without a Keycloak session in hand", () async {
      provider.tokens = null;
      final service = await aSignedInService();

      expect(await service.acceptTerms(version: "2026-09-16"), isFalse);
      expect(broker.acceptTermsCallCount, 0);
      expect(provider.refreshCalls, 0);
    });

    test("answers true when the account is right and the refresh didn't follow", () async {
      provider.tokens = AuthTokens(accessToken: _validToken("kc-access"));
      provider.refreshAnswer = false;
      final service = await aSignedInService();

      expect(await service.acceptTerms(version: "2026-09-16"), isTrue);
      expect(provider.refreshCalls, 1);
    });
  });
}
