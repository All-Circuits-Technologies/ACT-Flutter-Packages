// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

/// The configuration of an application which says nothing of its authentication.
const _noAuthConf = """
logs:
  level: warning
""";

/// The configuration of an application which names the broker it exchanges its tokens at.
const _brokerConf = """
auth:
  broker:
    url: "https://broker.example.test"
""";

/// The configuration of an application which names the three sides of its authentication.
const _wholeAuthConf = """
auth:
  broker:
    url: "https://broker.example.test"
  secrets:
    localStorage:
      saveUserIds: true
  oauth2:
    keycloak:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        issuer: "https://keycloak.example.test/realms/a-realm"
        scopes:
          - openid
""";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// The configuration of an application whose file says [content].
  Future<FakeTbExtenderConfig> aConfig([String content = _noAuthConf]) async {
    final config = await FakeTbExtenderConfig.withContent(content);
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinTbExtenderConf", () {
    test("reads the broker an application exchanges its tokens at", () async {
      final config = await aConfig(_brokerConf);

      expect(config.authBrokerUrl.load(), "https://broker.example.test");
    });

    test("reads no broker for an application which names none", () async {
      final config = await aConfig();

      expect(config.authBrokerUrl.load(), isNull);
    });

    test("reads the Keycloak realm and the local storage of the same application", () async {
      final config = await aConfig(_wholeAuthConf);

      expect(config.keycloakOAuth2Conf.load()?.clientId, "a-client-id");
      expect(config.saveUserIdsInStorage.load(), isTrue);
    });
  });
}
