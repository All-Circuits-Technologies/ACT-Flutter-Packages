// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

// The redirect URLs are read the way the core reads them, through its protected builders
// ignore_for_file: invalid_use_of_protected_member

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_keycloak_oauth2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  FakeKeycloakConfigManager? config;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    FakeAssets.stop();
    await config?.disposeLifeCycle();
    config = null;
    await globalManager.reset();
  });

  /// The provider of an application whose configuration is [content].
  Future<KeycloakOAuth2Provider<FakeKeycloakConfigManager>> aProvider(String content) async {
    config = await FakeKeycloakConfigManager.withContent(content);
    globalGetIt().registerSingleton<FakeKeycloakConfigManager>(config!);

    return KeycloakOAuth2Provider<FakeKeycloakConfigManager>(redirectUrl: aRedirectUrl);
  }

  group("MixinKeycloakOAuth2Conf.keycloakOAuth2Conf", () {
    test("reads the client of the application", () async {
      config = await FakeKeycloakConfigManager.withContent(aKeycloakConf);

      final conf = config!.keycloakOAuth2Conf.load();

      expect(conf?.clientId, "a-client-id");
      expect(conf?.appAuthRedirectScheme, "com.example.app");
      expect(conf?.scopes, ["openid", "profile"]);
    });

    test("keeps the realm the configuration names as the issuer", () async {
      config = await FakeKeycloakConfigManager.withContent(aKeycloakConf);

      expect(
        config!.keycloakOAuth2Conf.load()?.issuer,
        "https://keycloak.example.com/realms/a-realm",
      );
    });

    test("reads the endpoints a configuration names one by one", () async {
      config = await FakeKeycloakConfigManager.withContent("""
auth:
  oauth2:
    keycloak:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        scopes:
          - openid
        serviceConfiguration:
          authorizationEndpoint: "https://keycloak.example.com/auth"
          tokenEndpoint: "https://keycloak.example.com/token"
""");

      final conf = config!.keycloakOAuth2Conf.load();

      expect(conf?.issuer, isNull);
      expect(conf?.providerUrlConf?.tokenEndpoint, "https://keycloak.example.com/token");
    });

    test("reads nothing of a configuration which names no client", () async {
      config = await FakeKeycloakConfigManager.withContent("""
auth:
  oauth2:
    keycloak:
      config:
        appAuthRedirectScheme: "com.example.app"
        issuer: "https://keycloak.example.com/realms/a-realm"
        scopes:
          - openid
""");

      expect(config!.keycloakOAuth2Conf.load(), isNull);
    });

    test("reads nothing of a configuration which names no realm at all", () async {
      config = await FakeKeycloakConfigManager.withContent("""
auth:
  oauth2:
    keycloak:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        scopes:
          - openid
""");

      expect(config!.keycloakOAuth2Conf.load(), isNull);
    });

    test("reads nothing of a configuration which says nothing of Keycloak", () async {
      config = await FakeKeycloakConfigManager.withContent("auth:\n  oauth2:\n    other: {}");

      expect(config!.keycloakOAuth2Conf.load(), isNull);
    });
  });

  group("KeycloakOAuth2Provider.getDefaultOAuth2Conf", () {
    test("answers the client of the application", () async {
      final provider = await aProvider(aKeycloakConf);

      final conf = await provider.getDefaultOAuth2Conf();

      expect(conf.clientId, "a-client-id");
      expect(conf.issuer, "https://keycloak.example.com/realms/a-realm");
    });

    test("raises when the application names no client", () async {
      final provider = await aProvider("auth:\n  oauth2:\n    other: {}");

      expect(provider.getDefaultOAuth2Conf, throwsA(isA<NoKeycloakOAuth2ConfError>()));
    });
  });

  group("KeycloakOAuth2Provider.buildRedirectUrl", () {
    test("answers the URL the application was built with", () async {
      final provider = KeycloakOAuth2Provider<FakeKeycloakConfigManager>(
        redirectUrl: aRedirectUrl,
      );

      expect(await provider.buildRedirectUrl(), aRedirectUrl);
    });

    test("answers it whole, where the core would build a scheme with one slash", () async {
      final provider = KeycloakOAuth2Provider<FakeKeycloakConfigManager>(
        redirectUrl: aRedirectUrl,
      );

      expect(await provider.buildRedirectUrl(), isNot(contains(":/oauthredirect")));
    });
  });

  group("KeycloakOAuth2Provider.buildPostLogoutRedirectUrl", () {
    test("reuses the redirect URL when the application names no other one", () async {
      final provider = KeycloakOAuth2Provider<FakeKeycloakConfigManager>(
        redirectUrl: aRedirectUrl,
      );

      expect(await provider.buildPostLogoutRedirectUrl(), aRedirectUrl);
    });

    test("answers the URL the application named for the sign out", () async {
      final provider = KeycloakOAuth2Provider<FakeKeycloakConfigManager>(
        redirectUrl: aRedirectUrl,
        postLogoutRedirectUrl: "com.example.app://logout",
      );

      expect(await provider.buildPostLogoutRedirectUrl(), "com.example.app://logout");
      expect(await provider.buildRedirectUrl(), aRedirectUrl);
    });
  });

  group("NoKeycloakOAuth2ConfError", () {
    test("says that the configuration of Keycloak is missing or wrong", () {
      expect(NoKeycloakOAuth2ConfError().toString(), contains("Keycloak"));
    });
  });
}
