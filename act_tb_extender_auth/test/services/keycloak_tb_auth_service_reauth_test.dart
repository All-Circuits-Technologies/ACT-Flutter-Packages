// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

/// The user of the session, as the broker names it.
const _userA = BrokerUser(tbUserId: "user-A", customerId: "customer-id", email: "a@example.test");

/// Somebody else, who may sign in on the Keycloak form instead of the user of the session.
const _userB = BrokerUser(tbUserId: "user-B", customerId: "customer-id", email: "b@example.test");

BrokerLoginResponse _loginOf(BrokerUser user) => BrokerLoginResponse(
  tbToken: "tb-access",
  tbRefreshToken: "tb-refresh",
  expiresIn: 3600,
  user: user,
);

const _closed = AuthSignInResult(status: AuthSignInStatus.sessionExpired);
const _offline = AuthSignInResult(status: AuthSignInStatus.networkError);

void main() {
  late FakeGlobalManager globalManager;
  late FakeKeycloakProvider provider;
  late FakeBrokerClient broker;
  late FakeAuthStorage storage;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    provider = FakeKeycloakProvider();
    broker = FakeBrokerClient();
    storage = FakeAuthStorage();
  });

  tearDown(() => globalManager.reset());

  /// The service of a user A signed in a while ago: the ThingsBoard token of the previous run
  /// names them, the Keycloak session is alive, and the broker signs A in again unless a test
  /// says otherwise.
  Future<KeycloakTbAuthService> aServiceOfUserA() async {
    storage.stored = AuthTokens(
      accessToken: AuthToken(
        raw: fakeJwt({
          "sub": _userA.email,
          "userId": _userA.tbUserId,
          "customerId": _userA.customerId,
        }),
      ),
    );
    provider.tokens = const AuthTokens(accessToken: AuthToken(raw: "kc-access"));
    broker.onLogin = (_) => BrokerLoginSuccess(_loginOf(_userA));

    final service = KeycloakTbAuthService(
      keycloakProvider: provider,
      brokerClient: broker,
      keycloakStorageService: FakeAuthStorage(),
      tbTokenRefresher: (_) async => null,
      keycloakConfLoader: () => null,
    );
    await service.setStorageService(storage);
    expect(await service.getCurrentUserId(), "user-A", reason: "the setup must know its user");

    return service;
  }

  group("KeycloakTbAuthService.deleteAccountAfterRecentSignIn", () {
    test("signs the user in again, with max_age, before deleting the account", () async {
      final service = await aServiceOfUserA();

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result?.status, AuthDeleteStatus.done);
      expect(broker.loginCallCount, 1);
      expect(broker.deleteCallCount, 1);
      expect(provider.signInParameters, [
        {"max_age": "300"},
      ]);
    });

    test("hands Keycloak the age the application chose", () async {
      final service = await aServiceOfUserA();

      await service.deleteAccountAfterRecentSignIn(maxSignInAge: const Duration(minutes: 2));

      expect(provider.signInParameters, [
        {"max_age": "120"},
      ]);
    });

    // act_oauth2_core answers a sign in page the user closed with sessionExpired
    test("deletes nothing when the user closes the sign in page", () async {
      final service = await aServiceOfUserA();
      provider.redirectResults.add(_closed);

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result, isNull);
      expect(broker.deleteCallCount, 0);
      expect(provider.signOutCalled, isFalse);
    });

    test("reports a sign in which failed on the network", () async {
      final service = await aServiceOfUserA();
      provider.redirectResults.add(_offline);

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result?.status, AuthDeleteStatus.networkError);
      expect(broker.deleteCallCount, 0);
    });

    test("signs in again and retries once when the broker finds the sign in too old", () async {
      final service = await aServiceOfUserA();
      broker.deleteErrors.addAll([BrokerAuthError.reauthRequired, null]);

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result?.status, AuthDeleteStatus.done);
      expect(broker.loginCallCount, 2);
      expect(broker.deleteCallCount, 2);
      expect(provider.signInParameters, [
        {"max_age": "300"},
        {"max_age": "300"},
      ]);
    });

    // The Keycloak form lets another account sign in: B must neither delete itself on A's
    // request nor go on under the session of A, with A's caches and A's terms acceptance
    test("signs out and deletes nothing when another account signed in", () async {
      final service = await aServiceOfUserA();
      broker.onLogin = (_) => BrokerLoginSuccess(_loginOf(_userB));

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(broker.deleteCallCount, 0);
      expect(provider.signOutCalled, isTrue);
      expect(service.authStatus, AuthStatus.signedOut);
      expect(result?.status, AuthDeleteStatus.genericError);
      expect(result?.extra, BrokerAuthError.invalidToken);
    });

    test("gives up after the second refusal", () async {
      final service = await aServiceOfUserA();
      broker.deleteErrors.addAll([BrokerAuthError.reauthRequired, BrokerAuthError.reauthRequired]);

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result?.extra, BrokerAuthError.reauthRequired);
      expect(broker.deleteCallCount, 2);
      expect(provider.signOutCalled, isFalse, reason: "the session is kept, nothing was deleted");
    });

    test("does not retry a deletion which failed for another reason", () async {
      final service = await aServiceOfUserA();
      broker.deleteErrors.add(BrokerAuthError.network);

      final result = await service.deleteAccountAfterRecentSignIn();

      expect(result?.status, AuthDeleteStatus.networkError);
      expect(result?.extra, BrokerAuthError.network);
      expect(broker.deleteCallCount, 1);
    });
  });

  group("KeycloakTbAuthService.changePassword", () {
    // Only kc_action: AppAuth on Android throws on a login_hint among the additional parameters
    test("asks Keycloak for the password update", () async {
      final service = await aServiceOfUserA();

      final status = await service.changePassword();

      expect(status, AuthSignInStatus.done);
      expect(provider.signInParameters, [
        {"kc_action": "UPDATE_PASSWORD"},
      ]);
      expect(provider.signOutCalled, isFalse);
    });

    // act_oauth2_core answers a sign in page the user closed with sessionExpired
    test("has nothing to report when the user closes the page", () async {
      final service = await aServiceOfUserA();
      provider.redirectResults.add(_closed);

      expect(await service.changePassword(), isNull);
    });

    test("reports a sign in which failed", () async {
      final service = await aServiceOfUserA();
      provider.redirectResults.add(_offline);

      expect(await service.changePassword(), AuthSignInStatus.networkError);
    });

    // As for the deletion: B must not go on under the session of A
    test("signs out when another account signed in", () async {
      final service = await aServiceOfUserA();
      broker.onLogin = (_) => BrokerLoginSuccess(_loginOf(_userB));

      final status = await service.changePassword();

      expect(provider.signOutCalled, isTrue);
      expect(status, AuthSignInStatus.genericError);
    });
  });
}
