// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_google/act_oauth2_google.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_google_oauth2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  FakeGoogleConfigManager? config;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    FakeAssets.stop();
    await config?.disposeLifeCycle();
    config = null;
    await globalManager.reset();
  });

  /// The provider of an application whose configuration is [content].
  Future<GoogleOAuth2Provider<FakeGoogleConfigManager>> aProvider(String content) async {
    config = await FakeGoogleConfigManager.withContent(content);
    globalGetIt().registerSingleton<FakeGoogleConfigManager>(config!);

    return GoogleOAuth2Provider<FakeGoogleConfigManager>();
  }

  group("MixinGoogleOAuth2Conf.oauthClientConf", () {
    test("reads the client of the application", () async {
      config = await FakeGoogleConfigManager.withContent(aGoogleConf);

      final conf = config!.oauthClientConf.load();

      expect(conf?.clientId, "a-client-id");
      expect(conf?.appAuthRedirectScheme, "com.example.app");
      expect(conf?.scopes, ["openid", "email"]);
    });

    test("names Google as the issuer when the configuration names none", () async {
      config = await FakeGoogleConfigManager.withContent(aGoogleConf);

      expect(config!.oauthClientConf.load()?.issuer, "https://accounts.google.com");
    });

    test("keeps the issuer the configuration names", () async {
      config = await FakeGoogleConfigManager.withContent("""
auth:
  oauth2:
    google:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        issuer: "https://another.issuer"
        scopes:
          - openid
""");

      expect(config!.oauthClientConf.load()?.issuer, "https://another.issuer");
    });

    test("reads nothing of a configuration which names no client", () async {
      config = await FakeGoogleConfigManager.withContent("""
auth:
  oauth2:
    google:
      config:
        appAuthRedirectScheme: "com.example.app"
        scopes:
          - openid
""");

      expect(config!.oauthClientConf.load(), isNull);
    });

    test("reads nothing of a configuration which says nothing of Google", () async {
      config = await FakeGoogleConfigManager.withContent("auth:\n  oauth2:\n    other: {}");

      expect(config!.oauthClientConf.load(), isNull);
    });
  });

  group("GoogleOAuth2Provider.getDefaultOAuth2Conf", () {
    test("answers the client of the application", () async {
      final provider = await aProvider(aGoogleConf);

      final conf = await provider.getDefaultOAuth2Conf();

      expect(conf.clientId, "a-client-id");
      expect(conf.issuer, "https://accounts.google.com");
    });

    test("raises when the application names no client", () async {
      final provider = await aProvider("auth:\n  oauth2:\n    other: {}");

      expect(provider.getDefaultOAuth2Conf, throwsA(isA<NoGoogleOAuth2ConfError>()));
    });
  });

  group("NoGoogleOAuth2ConfError", () {
    test("says that the configuration of Google is missing or wrong", () {
      expect(NoGoogleOAuth2ConfError().toString(), contains("Google"));
    });
  });
}
