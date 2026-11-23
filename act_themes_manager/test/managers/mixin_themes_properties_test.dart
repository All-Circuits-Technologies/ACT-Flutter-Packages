// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_themes_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeThemesProperties properties;

  setUp(() async {
    properties = FakeThemesProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();
    addTearDown(properties.disposeLifeCycle);
  });

  group("MixinThemesProperties", () {
    test("keeps the theme the user chose between two runs", () async {
      await properties.currentTheme.store("blue");

      expect(await properties.currentTheme.load(), "blue");
    });

    test("keeps the brightness the user chose between two runs", () async {
      await properties.currentThemeLightMode.store(false);

      expect(await properties.currentThemeLightMode.load(), isFalse);
    });

    test("remembers nothing for a user who chose nothing", () async {
      expect(await properties.currentTheme.load(), isNull);
      expect(await properties.currentThemeLightMode.load(), isNull);
    });

    test("ends the streams of its items once the properties are disposed", () async {
      final disposed = FakeThemesProperties();
      final ended = Future.wait([
        expectLater(disposed.currentTheme.updateStream, emitsDone),
        expectLater(disposed.currentThemeLightMode.updateStream, emitsDone),
      ]);

      await disposed.disposeLifeCycle();

      await ended;
    });
  });
}
