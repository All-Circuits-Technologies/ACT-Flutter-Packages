// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

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
  late ActThemesManager manager;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    FakeAssets.serve({"assets/config/default.yaml": "themes:\n  dev:\n    force: false"});

    final config = FakeThemesConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    final properties = FakeThemesProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();

    manager = ActThemesManager(
      propertiesGetter: () => properties,
      configGetter: () => config,
      appThemes: FakeThemes.values,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    globalManager.managers.registerSingleton<ActThemesManager>(manager);
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// The bloc of the page of an application which shows its themes.
  FakeThemesBloc aBloc() {
    final bloc = FakeThemesBloc(const FakeThemesState(currentTheme: FakeThemes.blue));
    addTearDown(bloc.close);

    return bloc;
  }

  group("MixinActThemesBloc", () {
    test("shows the theme the user chooses", () async {
      final bloc = aBloc();

      await manager.setCurrentTheme(newTheme: FakeThemes.green);
      await pumpEventQueue();

      expect(bloc.state.currentTheme, FakeThemes.green);
    });

    test("shows the brightness the user chooses", () async {
      final bloc = aBloc();

      await manager.setBrightness(newBrightness: Brightness.dark);
      await pumpEventQueue();

      expect(bloc.state.brightness, Brightness.dark);
    });

    test("shows the brightness of the device once the user follows it again", () async {
      final bloc = aBloc();
      await manager.setBrightness(newBrightness: Brightness.dark);
      await pumpEventQueue();

      await manager.setBrightness(newBrightness: null);
      await pumpEventQueue();

      expect(bloc.state.brightness, isNull);
    });

    test("has the manager keep the theme the page asks for", () async {
      final bloc = aBloc();

      bloc.add(const AskToUpdateThemeEvent(newTheme: FakeThemes.green));
      await pumpEventQueue();

      expect(manager.currentTheme, FakeThemes.green);
      expect(bloc.state.currentTheme, FakeThemes.green);
    });

    test("has the manager keep the brightness the page asks for", () async {
      final bloc = aBloc();

      bloc.add(const AskToUpdateBrightnessEvent(newBrightness: Brightness.dark));
      await pumpEventQueue();

      expect(manager.brightness, Brightness.dark);
      expect(bloc.state.brightness, Brightness.dark);
    });

    test("stops following the themes once the page is closed", () async {
      final bloc = aBloc();

      await bloc.close();
      await manager.setCurrentTheme(newTheme: FakeThemes.green);
      await pumpEventQueue();

      expect(bloc.state.currentTheme, FakeThemes.blue);
    });
  });
}
