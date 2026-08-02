// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_locale_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  tearDown(FakeAssets.stop);

  /// Builds the configuration of an application which holds [configuration].
  Future<FakeLocaleConfig> aConfig(String configuration) async {
    FakeAssets.serve({"assets/config/default.yaml": configuration});

    final config = FakeLocaleConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinLocaleConfig.defaultWantedLocale", () {
    test("names no locale when the configuration names none", () async {
      final config = await aConfig("locale:\n  dev:\n    forceWanted: false");

      expect(config.defaultWantedLocale.load(), isNull);
    });

    test("names the locale the configuration names", () async {
      final config = await aConfig('locale:\n  defaultWanted: "fr-FR"');

      expect(config.defaultWantedLocale.load(), "fr-FR");
    });
  });

  group("MixinLocaleConfig.forceWantedLocaleInDev", () {
    test("forces nothing when the configuration says nothing", () async {
      final config = await aConfig('locale:\n  defaultWanted: "fr-FR"');

      expect(config.forceWantedLocaleInDev.load(), isFalse);
    });

    test("forces the locale when the configuration asks for it", () async {
      final config = await aConfig("locale:\n  dev:\n    forceWanted: true");

      expect(config.forceWantedLocaleInDev.load(), isTrue);
    });
  });
}
