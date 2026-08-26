// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_logger_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLoggerConfigManager config;

  tearDown(() async {
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  group("MixinCslLoggerConfig", () {
    test("reads the level of the console logger from the configuration", () async {
      config = await FakeLoggerConfigManager.withContent(
        "logs:\n  console:\n    level: error",
      );

      expect(config.cslLogLevelEnv.load(), LogsLevel.error);
    });

    test("keeps every message when the configuration gives no level", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: warning");

      expect(config.cslLogLevelEnv.load(), LogsLevel.all);
    });

    test("reads whether the logs are printed in release from the configuration", () async {
      config = await FakeLoggerConfigManager.withContent(
        "logs:\n  console:\n    printInRelease: true",
      );

      expect(config.logPrintInReleaseEnv.load(), isTrue);
    });

    test("doesn't print in release when the configuration says nothing", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: warning");

      expect(config.logPrintInReleaseEnv.load(), isFalse);
    });

    test("reads its variables under the keys of the console logger", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: warning");

      expect(config.cslLogLevelEnv.key, "logs.console.level");
      expect(config.logPrintInReleaseEnv.key, "logs.console.printInRelease");
    });
  });
}
