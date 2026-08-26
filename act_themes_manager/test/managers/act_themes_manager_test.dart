// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_themes_manager/act_themes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_themes_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeThemesProperties properties;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    properties = FakeThemesProperties();
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// Builds the themes manager of an application, and initializes it.
  ///
  /// The application knows [appThemes], its configuration names [defaultTheme] and forces it in
  /// development when [forceThemeInDev] is true, and the user chose [storedTheme] and
  /// [storedLightMode] the last time.
  Future<ActThemesManager> aManager({
    List<MixinActThemes> appThemes = FakeThemes.values,
    String? defaultTheme,
    bool forceThemeInDev = false,
    bool? forceLightModeInDevValue,
    Environment env = Environment.development,
    String? storedTheme,
    bool? storedLightMode,
  }) async {
    final defaultLine = defaultTheme == null ? "" : '  default: "$defaultTheme"\n';
    final forceLightModeLine = forceLightModeInDevValue == null
        ? ""
        : "    forceLightModeValue: $forceLightModeInDevValue\n";
    FakeAssets.serve({
      "assets/config/default.yaml":
          "themes:\n$defaultLine  dev:\n    force: $forceThemeInDev\n$forceLightModeLine",
    });

    final config = FakeThemesConfig(env: env);
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    await properties.initLifeCycle();
    await properties.deleteAll();
    if (storedTheme != null) {
      await properties.currentTheme.store(storedTheme);
    }
    if (storedLightMode != null) {
      await properties.currentThemeLightMode.store(storedLightMode);
    }

    final manager = ActThemesManager(
      propertiesGetter: () => properties,
      configGetter: () => config,
      appThemes: appThemes,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("ActThemesManager", () {
    test("refuses to be built for an application which has no theme", () {
      expect(
        () => ActThemesManager(
          propertiesGetter: () => properties,
          configGetter: FakeThemesConfig.new,
          appThemes: const [],
        ),
        throwsA(isA<ActThemesNotDefinedError>()),
      );
    });
  });

  group("ActThemesManager.initLifeCycle", () {
    test("starts with the theme the user chose the last time", () async {
      final manager = await aManager(storedTheme: FakeThemes.green.stringValue);

      expect(manager.currentTheme, FakeThemes.green);
    });

    test("starts with the theme of the configuration when the user chose none", () async {
      final manager = await aManager(defaultTheme: FakeThemes.green.stringValue);

      expect(manager.currentTheme, FakeThemes.green);
    });

    test("starts with the first theme of the application when nothing names one", () async {
      final manager = await aManager();

      expect(manager.currentTheme, FakeThemes.blue);
    });

    test("starts with the first theme when the configuration names an unknown one", () async {
      final manager = await aManager(defaultTheme: "aThemeWhichDoesNotExist");

      expect(manager.currentTheme, FakeThemes.blue);
    });

    test("takes the theme of the configuration over the stored one in development", () async {
      final manager = await aManager(
        defaultTheme: FakeThemes.blue.stringValue,
        forceThemeInDev: true,
        storedTheme: FakeThemes.green.stringValue,
      );

      expect(manager.currentTheme, FakeThemes.blue);
    });

    test("keeps the theme the user chose outside of development", () async {
      final manager = await aManager(
        env: Environment.production,
        defaultTheme: FakeThemes.blue.stringValue,
        forceThemeInDev: true,
        storedTheme: FakeThemes.green.stringValue,
      );

      expect(manager.currentTheme, FakeThemes.green);
    });

    test("starts with the brightness the user chose the last time", () async {
      final manager = await aManager(storedLightMode: false);

      expect(manager.brightness, Brightness.dark);
    });

    test("starts with the brightness of the device when the user chose none", () async {
      final manager = await aManager();

      expect(manager.brightness, isNull);
    });

    test("takes the brightness of the configuration in development", () async {
      final manager = await aManager(forceLightModeInDevValue: false, storedLightMode: true);

      expect(manager.brightness, Brightness.dark);
    });

    test("keeps the brightness the user chose outside of development", () async {
      final manager = await aManager(
        env: Environment.production,
        forceLightModeInDevValue: false,
        storedLightMode: true,
      );

      expect(manager.brightness, Brightness.light);
    });
  });

  group("ActThemesManager.setCurrentTheme", () {
    test("keeps the theme which was chosen, and pushes it on its stream", () async {
      final manager = await aManager();

      final pushed = expectLater(manager.currentThemeStream, emits(FakeThemes.green));
      await manager.setCurrentTheme(newTheme: FakeThemes.green);

      expect(manager.currentTheme, FakeThemes.green);
      await pushed;
    });

    test("remembers the theme which was chosen for the next run", () async {
      final manager = await aManager();

      await manager.setCurrentTheme(newTheme: FakeThemes.green);

      expect(await properties.currentTheme.load(), FakeThemes.green.stringValue);
    });

    test("refuses a theme the application does not know", () async {
      final manager = await aManager(appThemes: const [FakeThemes.blue]);

      await manager.setCurrentTheme(newTheme: FakeThemes.green);

      expect(manager.currentTheme, FakeThemes.blue);
      expect(await properties.currentTheme.load(), isNull);
    });
  });

  group("ActThemesManager.setBrightness", () {
    test("keeps the brightness which was chosen, and pushes it on its stream", () async {
      final manager = await aManager();

      final pushed = expectLater(manager.brightnessStream, emits(Brightness.dark));
      await manager.setBrightness(newBrightness: Brightness.dark);

      expect(manager.brightness, Brightness.dark);
      await pushed;
    });

    test("remembers the brightness which was chosen for the next run", () async {
      final manager = await aManager();

      await manager.setBrightness(newBrightness: Brightness.light);

      expect(await properties.currentThemeLightMode.load(), isTrue);
    });

    test("forgets the brightness when the application follows the device again", () async {
      final manager = await aManager(storedLightMode: true);

      await manager.setBrightness(newBrightness: null);

      expect(manager.brightness, isNull);
      expect(await properties.currentThemeLightMode.load(), isNull);
    });
  });
}
