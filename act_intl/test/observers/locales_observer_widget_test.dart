// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_intl/act_intl.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_locale_app.dart';

void main() {
  late FakeGlobalManager globalManager;
  late LocalesManager manager;

  setUp(() {
    globalManager = FakeGlobalManager.install();

    // The widget only hands the manager the locale of the device, which the manager keeps without
    // reading anything of the application.
    manager = LocalesManager(
      getSupportedLocales: () => const [Locale("fr", "FR")],
      propertiesGetter: FakeLocaleProperties.new,
      configGetter: FakeLocaleConfig.new,
    );
    globalManager.managers.registerSingleton<LocalesManager>(manager);
  });

  tearDown(() async {
    await manager.disposeLifeCycle();
    await globalManager.reset();
  });

  /// Shows a page which watches the locale of the device.
  Future<void> aPage(WidgetTester tester, {Widget? child}) =>
      tester.pumpWidget(LocalesObserverWidget(child: child));

  /// Tells the page that the device now reads [locale].
  Future<void> theDeviceReads(WidgetTester tester, Locale locale) async {
    tester.binding.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pump();
  }

  group("LocalesObserverWidget", () {
    testWidgets("shows the page it wraps", (tester) async {
      await aPage(
        tester,
        child: const Directionality(textDirection: TextDirection.ltr, child: Text("the page")),
      );

      expect(find.text("the page"), findsOneWidget);
    });

    testWidgets("shows nothing when it wraps no page", (tester) async {
      await aPage(tester);

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets("hands the manager the locale the device reads", (tester) async {
      await aPage(tester);

      await theDeviceReads(tester, const Locale("fr", "FR"));

      expect(manager.currentLocale, const Locale("fr", "FR"));
    });

    testWidgets("tells the application that the locale changed", (tester) async {
      await aPage(tester);
      final locales = <Locale>[];
      final subscription = manager.currentLocaleStream.listen(locales.add);
      addTearDown(subscription.cancel);

      await theDeviceReads(tester, const Locale("fr", "FR"));
      await tester.pump();

      expect(locales, const [Locale("fr", "FR")]);
    });

    testWidgets("stops watching the device once the page is gone", (tester) async {
      await aPage(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await theDeviceReads(tester, const Locale("fr", "FR"));

      expect(manager.currentLocale, const Locale.fromSubtags());
    });
  });
}
