// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_locale_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeLocaleProperties properties;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    properties = FakeLocaleProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();
  });

  tearDown(() => globalManager.reset());

  group("MixinLocaleProperties.wantedLocale", () {
    test("remembers nothing before the user chose a locale", () async {
      expect(await properties.wantedLocale.load(), isNull);
    });

    test("remembers the locale the user chose", () async {
      await properties.wantedLocale.store("fr-FR");

      expect(await properties.wantedLocale.load(), "fr-FR");
    });

    test("forgets the locale the user chose once the properties are cleared", () async {
      await properties.wantedLocale.store("fr-FR");

      await properties.deleteAll();

      expect(await properties.wantedLocale.load(), isNull);
    });
  });
}
