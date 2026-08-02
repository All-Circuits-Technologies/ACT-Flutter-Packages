// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_config.dart';

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// Shows the page of an application which runs in [env], and gives back the banner it wears.
  ///
  /// The page wears no banner when the environment is not worth one, and the answer is then null.
  Future<Banner?> aPage(WidgetTester tester, Environment env) async {
    globalManager.managers.registerSingleton<FakeAppConfig>(FakeAppConfig(env: env));

    await tester.pumpWidget(
      MaterialApp(
        home: EnvBanner.displayAppBarBanner<FakeAppConfig>(child: const Text("the page")),
      ),
    );

    final banners = tester.widgetList<Banner>(find.byType(EnvBanner));

    return banners.isEmpty ? null : banners.single;
  }

  group("EnvBanner.displayAppBarBanner", () {
    testWidgets("shows the page it was given", (tester) async {
      await aPage(tester, Environment.development);

      expect(find.text("the page"), findsOneWidget);
    });

    testWidgets("names the environment the application runs in", (tester) async {
      final banner = await aPage(tester, Environment.development);

      expect(banner?.message, "DEV");
    });

    testWidgets("marks the development environment in red", (tester) async {
      final banner = await aPage(tester, Environment.development);

      expect(banner?.color, Colors.red);
    });

    testWidgets("marks the qualification environment in blue", (tester) async {
      final banner = await aPage(tester, Environment.qualification);

      expect(banner?.color, Colors.blue);
    });

    testWidgets("marks the production environment in green", (tester) async {
      final banner = await aPage(tester, Environment.production);

      expect(banner?.color, Colors.green);
    });

    testWidgets("hangs the banner where it hides no widget of the page", (tester) async {
      final banner = await aPage(tester, Environment.development);

      expect(banner?.location, BannerLocation.topStart);
    });

    testWidgets("shows no banner for an environment which has no short name", (tester) async {
      final banner = await aPage(tester, Environment.local);

      expect(banner, isNull);
      expect(find.text("the page"), findsOneWidget);
    });
  });
}
