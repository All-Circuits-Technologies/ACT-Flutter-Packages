// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_intl_ui/act_intl_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_intl_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeLocalesApp locales;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    FakeAssets.stop();
    await locales.dispose();
    await globalManager.reset();
  });

  /// The bloc of a page which follows the locale the user chose.
  ///
  /// The locale the user chose the last time is [storedLocale].
  Future<FakeGetLocaleBloc> aGetBloc({String? storedLocale}) async {
    locales = await FakeLocalesApp.install(globalManager, storedLocale: storedLocale);

    final bloc = FakeGetLocaleBloc();
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  /// The bloc of a page which lets the user choose the locale.
  Future<FakeSetLocaleBloc> aSetBloc({String? storedLocale}) async {
    locales = await FakeLocalesApp.install(globalManager, storedLocale: storedLocale);

    final bloc = FakeSetLocaleBloc();
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  group("MixinGetWantedLocaleBloc", () {
    test("shows the locale the user chose the last time", () async {
      final bloc = await aGetBloc(storedLocale: "fr-FR");

      expect(bloc.state.wantedLocale, const Locale("fr", "FR"));
    });

    test("shows that the application follows the device when the user chose nothing", () async {
      final bloc = await aGetBloc();

      expect(bloc.state.wantedLocale, isNull);
    });

    test("follows the locale the user chooses", () async {
      final bloc = await aGetBloc();

      locales.manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(bloc.state.wantedLocale, const Locale("fr", "FR"));
    });

    test("follows the user who asks for the locale of the device again", () async {
      final bloc = await aGetBloc(storedLocale: "fr-FR");

      locales.manager.wantedLocale = null;
      await pumpEventQueue();

      expect(bloc.state.wantedLocale, isNull);
    });

    test("stops following the locales once the page is closed", () async {
      final bloc = await aGetBloc();

      await bloc.close();
      locales.manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(bloc.state.wantedLocale, isNull);
    });
  });

  group("MixinSetWantedLocaleBloc", () {
    test("shows the locale the application holds when the page is built", () async {
      final bloc = await aSetBloc(storedLocale: "fr-FR");

      expect(bloc.state.currentLocale, locales.manager.currentLocale);
    });

    test("has the manager keep the locale the user chose", () async {
      final bloc = await aSetBloc();

      bloc.add(const NewLocaleWantedByUserEvent(wantedLocale: Locale("fr", "FR")));
      await pumpEventQueue();

      expect(locales.manager.wantedLocale, const Locale("fr", "FR"));
      expect(bloc.state.wantedLocale, const Locale("fr", "FR"));
    });

    test("shows the locale of the application once it changed", () async {
      final bloc = await aSetBloc();

      bloc.add(const NewLocaleWantedByUserEvent(wantedLocale: Locale("fr", "FR")));
      await pumpEventQueue();

      expect(bloc.state.currentLocale, const Locale("fr", "FR"));
    });

    test("has the manager follow the device again when the user asks for it", () async {
      final bloc = await aSetBloc(storedLocale: "fr-FR");

      bloc.add(const NewLocaleWantedByUserEvent(wantedLocale: null));
      await pumpEventQueue();

      expect(locales.manager.wantedLocale, isNull);
      expect(bloc.state.wantedLocale, isNull);
    });

    test("stops following the locales once the page is closed", () async {
      final bloc = await aSetBloc();
      final locale = bloc.state.currentLocale;

      await bloc.close();
      locales.manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(bloc.state.currentLocale, locale);
    });
  });
}
