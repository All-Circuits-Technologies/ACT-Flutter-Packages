// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  /// The secrets of an application which holds the two sets of tokens.
  Future<FakeTbExtenderSecrets> someSecrets() async {
    final config = await FakeTbExtenderConfig.withContent("logs:\n  level: warning");
    addTearDown(config.disposeLifeCycle);
    final properties = FakeTbExtenderProperties();

    return FakeTbExtenderSecrets(propertiesGetter: () => properties, confGetter: () => config);
  }

  group("MixinKeycloakAuthSecrets", () {
    test("keeps the Keycloak tokens beside the ThingsBoard ones, under their own key", () async {
      final secrets = await someSecrets();

      expect(secrets.keycloakTokens.key, "KC_AUTH_TOKENS");
      expect(secrets.keycloakTokens.key, isNot(secrets.authTokens.key));
    });

    test("keeps the Keycloak tokens on the device they were minted on", () async {
      final secrets = await someSecrets();

      expect(secrets.keycloakTokens.doNotMigrate, isTrue);
    });
  });
}
