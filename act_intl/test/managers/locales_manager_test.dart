// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_locale_app.dart';

/// The locales the application under test is translated in.
const _supportedLocales = [Locale("en", "GB"), Locale("fr", "FR")];

/// The locale the device of the tests reads.
final _deviceLocale = LocaleUtility.localeFromString(string: Intl.getCurrentLocale())!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeLocaleProperties properties;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    properties = FakeLocaleProperties();
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// Builds the locales manager of an application, and initializes it.
  ///
  /// The application is translated in [supportedLocales], its configuration names
  /// [defaultWantedLocale] and forces it in development when [forceWantedLocaleInDev] is true, and
  /// the locale the user chose the last time is [storedLocale].
  Future<LocalesManager> aManager({
    List<Locale> supportedLocales = _supportedLocales,
    String? defaultWantedLocale,
    bool forceWantedLocaleInDev = false,
    Environment env = Environment.development,
    String? storedLocale,
  }) async {
    final defaultLine = defaultWantedLocale == null
        ? ""
        : '  defaultWanted: "$defaultWantedLocale"\n';
    FakeAssets.serve({
      "assets/config/default.yaml":
          "locale:\n$defaultLine  dev:\n    forceWanted: $forceWantedLocaleInDev",
    });

    final config = FakeLocaleConfig(env: env);
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    await properties.initLifeCycle();
    await properties.deleteAll();
    if (storedLocale != null) {
      await properties.wantedLocale.store(storedLocale);
    }

    final manager = LocalesManager(
      getSupportedLocales: () => supportedLocales,
      propertiesGetter: () => properties,
      configGetter: () => config,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  /// Shows the page of the application and tells [manager] that the view is up.
  ///
  /// The page holds the observer of the locales unless [withObserver] is false, which is what an
  /// application which forgot it looks like.
  Future<void> theViewIsShown(
    WidgetTester tester,
    LocalesManager manager, {
    bool withObserver = true,
  }) async {
    late BuildContext pageContext;
    final page = Builder(
      builder: (context) {
        pageContext = context;

        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(withObserver ? LocalesObserverWidget(child: page) : page);
    await manager.initAfterView(pageContext);
  }

  group("LocalesManagerBuilder", () {
    test("depends on the logger, on the properties and on the configuration", () {
      final builder = LocalesManagerBuilder<FakeLocaleConfig, FakeLocaleProperties>(
        getSupportedLocales: () => _supportedLocales,
      );

      expect(builder.dependsOn(), [LoggerManager, FakeLocaleProperties, FakeLocaleConfig]);
    });
  });

  group("LocalesManager.initLifeCycle", () {
    test("keeps the locales the application is translated in", () async {
      final manager = await aManager();

      expect(manager.supportedLocales, _supportedLocales);
    });

    test("wants no locale when nothing was stored and the configuration names none", () async {
      final manager = await aManager();

      expect(manager.wantedLocale, isNull);
    });

    test("wants the locale the configuration names when nothing was stored", () async {
      final manager = await aManager(defaultWantedLocale: "fr-FR");

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("wants the locale the user chose the last time", () async {
      final manager = await aManager(storedLocale: "fr-FR");

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("wants the stored locale over the one the configuration names", () async {
      final manager = await aManager(defaultWantedLocale: "en-GB", storedLocale: "fr-FR");

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("wants the configured locale over the stored one when development forces it", () async {
      final manager = await aManager(
        defaultWantedLocale: "en-GB",
        forceWantedLocaleInDev: true,
        storedLocale: "fr-FR",
      );

      expect(manager.wantedLocale, const Locale("en", "GB"));
    });

    test("wants the stored locale outside development, whatever development forces", () async {
      final manager = await aManager(
        defaultWantedLocale: "en-GB",
        forceWantedLocaleInDev: true,
        storedLocale: "fr-FR",
        env: Environment.qualification,
      );

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("wants nothing of a stored locale the application is not translated in", () async {
      final manager = await aManager(storedLocale: "de-DE");

      expect(manager.wantedLocale, isNull);
    });

    test("wants nothing of a configured locale the application is not translated in", () async {
      final manager = await aManager(defaultWantedLocale: "de-DE");

      expect(manager.wantedLocale, isNull);
    });
  });

  group("LocalesManager.initAfterView", () {
    testWidgets("shows the application in the locale it wants", (tester) async {
      final manager = await aManager(defaultWantedLocale: "fr-FR");

      await theViewIsShown(tester, manager);

      expect(manager.currentLocale, const Locale("fr", "FR"));
    });

    testWidgets("shows the application in the locale of the device when it wants none", (
      tester,
    ) async {
      final manager = await aManager();

      await theViewIsShown(tester, manager);

      expect(manager.currentLocale, _deviceLocale);
    });

    testWidgets("shows the application even when the page does not watch the device", (
      tester,
    ) async {
      final manager = await aManager(defaultWantedLocale: "fr-FR");

      await theViewIsShown(tester, manager, withObserver: false);

      expect(manager.currentLocale, const Locale("fr", "FR"));
    });
  });

  group("LocalesManager.wantedLocale", () {
    test("keeps the locale the user chose", () async {
      final manager = await aManager();

      manager.wantedLocale = const Locale("fr", "FR");

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("shows the application in the locale the user chose", () async {
      final manager = await aManager();

      manager.wantedLocale = const Locale("fr", "FR");

      expect(manager.currentLocale, const Locale("fr", "FR"));
    });

    test("tells the application which locale the user chose", () async {
      final manager = await aManager();
      final wanted = <Locale?>[];
      final subscription = manager.wantedLocaleStream.listen(wanted.add);
      addTearDown(subscription.cancel);

      manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(wanted, const [Locale("fr", "FR")]);
    });

    test("tells the application which locale it now shows", () async {
      final manager = await aManager();
      final current = <Locale>[];
      final subscription = manager.currentLocaleStream.listen(current.add);
      addTearDown(subscription.cancel);

      manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(current, const [Locale("fr", "FR")]);
    });

    test("remembers the locale the user chose for the next start", () async {
      final manager = await aManager();

      manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(await properties.wantedLocale.load(), "fr-FR");
    });

    test("refuses a locale the application is not translated in", () async {
      final manager = await aManager(storedLocale: "fr-FR");

      manager.wantedLocale = const Locale("de", "DE");

      expect(manager.wantedLocale, const Locale("fr", "FR"));
    });

    test("does nothing when the user chooses the locale which is already wanted", () async {
      final manager = await aManager(storedLocale: "fr-FR");
      final wanted = <Locale?>[];
      final subscription = manager.wantedLocaleStream.listen(wanted.add);
      addTearDown(subscription.cancel);

      manager.wantedLocale = const Locale("fr", "FR");
      await pumpEventQueue();

      expect(wanted, isEmpty);
    });

    test("forgets the locale the user chose when the user chooses none", () async {
      final manager = await aManager(storedLocale: "fr-FR");

      manager.wantedLocale = null;
      await pumpEventQueue();

      expect(manager.wantedLocale, isNull);
      expect(await properties.wantedLocale.load(), isNull);
    });

    test(
      "keeps showing the application in the locale it shows when the user chooses none",
      () async {
        final manager = await aManager(storedLocale: "fr-FR");
        manager.wantedLocale = const Locale("en", "GB");

        manager.wantedLocale = null;

        expect(manager.currentLocale, const Locale("en", "GB"));
      },
    );
  });

  group("LocalesManager.currentLocaleStrForDateFormat", () {
    test("writes the locale the way the formatting of a date expects it", () async {
      final manager = await aManager();

      manager.wantedLocale = const Locale("fr", "FR");

      expect(manager.currentLocaleStrForDateFormat, "fr_FR");
    });
  });

  group("LocalesManager.disposeLifeCycle", () {
    test("stops telling the application about the locales", () async {
      final manager = await aManager();
      final currentIsDone = expectLater(manager.currentLocaleStream, emitsDone);
      final wantedIsDone = expectLater(manager.wantedLocaleStream, emitsDone);

      await manager.disposeLifeCycle();

      await currentIsDone;
      await wantedIsDone;
    });
  });
}
