// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final uri = Uri.parse("https://an.host/a/page");

  late FakeLogger logger;
  late FakeGlobalManager globalManager;

  setUp(() {
    logger = FakeLogger();
    globalManager = FakeGlobalManager.install(logger: logger);
  });

  tearDown(() => globalManager.reset());

  group("UrlLauncherUtility.openUrlInBrowser", () {
    test("hands the url to the platform when it knows how to open it", () async {
      final launcher = FakeUrlLauncher.install();

      await UrlLauncherUtility.openUrlInBrowser(uri);

      expect(launcher.launchedUrls, [uri.toString()]);
    });

    test("says the url was opened when the platform opened it", () async {
      FakeUrlLauncher.install();

      expect(await UrlLauncherUtility.openUrlInBrowser(uri), isTrue);
    });

    test("asks the platform before handing it the url", () async {
      final launcher = FakeUrlLauncher.install(canLaunchAnswer: false);

      await UrlLauncherUtility.openUrlInBrowser(uri);

      expect(launcher.askedUrls, [uri.toString()]);
      expect(launcher.launchedUrls, isEmpty);
    });

    test("says the url was not opened when the platform cannot open it", () async {
      FakeUrlLauncher.install(canLaunchAnswer: false);

      expect(await UrlLauncherUtility.openUrlInBrowser(uri), isFalse);
    });

    test("warns when the platform cannot open the url", () async {
      FakeUrlLauncher.install(canLaunchAnswer: false);

      await UrlLauncherUtility.openUrlInBrowser(uri);

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });

    test("says the url was not opened when the platform gave up on it", () async {
      FakeUrlLauncher.install(launchAnswer: false);

      expect(await UrlLauncherUtility.openUrlInBrowser(uri), isFalse);
    });
  });
}
