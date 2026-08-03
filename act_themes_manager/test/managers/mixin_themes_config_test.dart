// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_themes_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  /// The configuration of an application whose file says [content].
  Future<FakeThemesConfig> aConfig(String content) async {
    FakeAssets.serve({"assets/config/default.yaml": content});

    final config = FakeThemesConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinThemesConfig", () {
    test("reads the theme the application starts with", () async {
      final config = await aConfig('themes:\n  default: "blue"');

      expect(config.defaultTheme.load(), "blue");
    });

    test("names no theme when the application named none", () async {
      final config = await aConfig("themes:\n  dev:\n    force: false");

      expect(config.defaultTheme.load(), isNull);
    });

    test("reads whether the theme of the application is forced in development", () async {
      final config = await aConfig("themes:\n  dev:\n    force: true");

      expect(config.forceThemeInDev.load(), isTrue);
    });

    test("keeps the theme the user chose when the application says nothing", () async {
      final config = await aConfig('themes:\n  default: "blue"');

      expect(config.forceThemeInDev.load(), isFalse);
    });

    test("reads the brightness which is forced in development", () async {
      final config = await aConfig("themes:\n  dev:\n    forceLightModeValue: false");

      expect(config.forceLightModeInDevValue.load(), isFalse);
    });

    test("forces no brightness when the application named none", () async {
      final config = await aConfig('themes:\n  default: "blue"');

      expect(config.forceLightModeInDevValue.load(), isNull);
    });
  });
}
