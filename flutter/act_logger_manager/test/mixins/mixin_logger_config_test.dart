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

  group("MixinLoggerConfig", () {
    test("reads the level of the logs from the configuration", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: info");

      expect(config.logLevelEnv.load(), LogsLevel.info);
    });

    test("falls back on the warning level when the configuration gives none", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  logsNb: 3");

      expect(config.logLevelEnv.load(), LogsLevel.warn);
    });

    test("falls back on the warning level when the configured level is unknown", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: chatty");

      expect(config.logLevelEnv.load(), LogsLevel.warn);
    });

    test("reads the level under the key of the manager", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: info");

      expect(config.logLevelEnv.key, "logs.level");
    });
  });
}
