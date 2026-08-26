// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAppConfigManager config;

  tearDown(() async {
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  group("AbsUsualConfigManager", () {
    test("is a config manager", () async {
      config = await FakeAppConfigManager.withContent("logs:\n  level: info");

      expect(config, isA<AbstractConfigManager>());
    });

    test("carries the variables the logger manager reads", () async {
      config = await FakeAppConfigManager.withContent("logs:\n  level: info");

      expect(config, isA<MixinDefaultLoggerConfig>());
    });

    test("reads the level of the logs of the application", () async {
      config = await FakeAppConfigManager.withContent("logs:\n  level: info");

      expect(config.logLevelEnv.load(), LogsLevel.info);
    });

    test("reads the variables of the console logger", () async {
      config = await FakeAppConfigManager.withContent(
        "logs:\n  console:\n    level: error\n    printInRelease: true",
      );

      expect(config.cslLogLevelEnv.load(), LogsLevel.error);
      expect(config.logPrintInReleaseEnv.load(), isTrue);
    });
  });
}
