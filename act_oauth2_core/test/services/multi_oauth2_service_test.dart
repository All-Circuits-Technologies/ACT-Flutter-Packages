// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_oauth2.dart';

/// The configuration of the provider the tests sign their users in with.
const _conf = DefaultOAuth2Conf(
  clientId: "aClient",
  issuer: "https://a.provider",
  discoveryUrl: null,
  providerUrlConf: null,
  scopes: ["openid"],
  appAuthRedirectScheme: "com.example.app",
);

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// The service of an application which offers [providers] to its users.
  Future<MultiOAuth2Service<FakeProviders>> aService(
    Map<FakeProviders, MixinAuthService> providers, {
    FakeProviders? currentProvider,
  }) async {
    final service = MultiOAuth2Service<FakeProviders>(
      providers: providers,
      currentProvider: currentProvider,
    );
    await service.initLifeCycle();
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("MultiOAuth2Service.initLifeCycle", () {
    test("initializes the providers which speak OAuth 2", () async {
      final provider = FakeOAuth2Service(conf: _conf);

      await aService({FakeProviders.identity: provider});

      expect(provider.authStatus, AuthStatus.signedOut);
      expect(provider.logCategories, ["multiOauth2", "aProvider"]);
    });

    test("leaves the providers which speak something else alone", () async {
      final other = FakeOtherService();

      final service = await aService({FakeProviders.legacy: other});

      expect(service.providers, {FakeProviders.legacy: other});
    });

    test("speaks to the only provider of the application", () async {
      final other = FakeOtherService();
      final service = await aService({FakeProviders.legacy: other});

      await service.signOut();

      expect(other.signedOut, isTrue);
    });

    test("speaks to the provider the application named among the ones it offers", () async {
      final other = FakeOtherService();
      final service = await aService({
        FakeProviders.identity: FakeOAuth2Service(conf: _conf),
        FakeProviders.legacy: other,
      }, currentProvider: FakeProviders.legacy);

      await service.signOut();

      expect(other.signedOut, isTrue);
    });
  });

  group("MultiOAuth2Service.clearProviders", () {
    test("closes the providers which speak OAuth 2", () async {
      final provider = FakeOAuth2Service(conf: _conf);
      final service = await aService({FakeProviders.identity: provider});

      await service.clearProviders();

      expect(service.providers, isEmpty);
      expect(provider.authStatusStream, emitsDone);
    });
  });
}
