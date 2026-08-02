// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// A configuration manager which declares the variables the tests read.
class _TestConfigManager extends AbstractConfigManager {
  /// The level of the logs, which has a default value.
  final logLevel = const NotNullableConfigVar<String>("logs.level", defaultValue: "info");

  /// The number of log files to keep.
  final logsNb = const ConfigVar<int>("logs.logsNb");

  /// Class constructor
  _TestConfigManager({required super.logger, super.configPath});
}

/// A builder of the manager the tests use.
class _TestConfigBuilder extends AbstractConfigBuilder<_TestConfigManager> {
  /// Class constructor
  _TestConfigBuilder(super.factory);
}

/// The folder the configuration files are read from.
const _configPath = "assets/config/";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    FakeAssets.stop();
    dotenv.clean();
    await ConfigSingleton.instanceOrNull?.disposeLifeCycle();
  });

  group("AbstractConfigManager", () {
    test("is a manager with a life cycle", () {
      expect(_TestConfigManager(logger: const SilentLogger()), isA<AbsWithLifeCycle>());
    });

    test("reads the configuration from the assets folder by default", () {
      final manager = _TestConfigManager(logger: const SilentLogger());

      expect(manager.configPath, "assets/config/");
    });

    test("falls back on the development environment when none is chosen at build time", () {
      final manager = _TestConfigManager(logger: const SilentLogger());

      expect(manager.env, Environment.development);
    });

    test("logs under its own category", () {
      final logger = FakeLogger();
      _TestConfigManager(logger: logger);

      expect(logger.records, isEmpty);
    });
  });

  group("AbstractConfigManager.initLifeCycle", () {
    test("makes the values of the configuration files readable", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: warning\n  logsNb: 3"});
      final manager = _TestConfigManager(logger: const SilentLogger());

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "warning");
      expect(manager.logsNb.load(), 3);
    });

    test("reads the files of the folder it is given", () async {
      FakeAssets.serve({"other/config/default.yaml": "logs:\n  level: error"});
      final manager = _TestConfigManager(logger: const SilentLogger(), configPath: "other/config/");

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "error");
    });

    test("lets the environment variables override the configuration files", () async {
      FakeAssets.serve({
        "${_configPath}default.yaml": "logs:\n  level: warning",
        "${_configPath}env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL",
        "$_configPath.env": "LOGS_LEVEL=trace",
      });
      final manager = _TestConfigManager(logger: const SilentLogger());

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "trace");
    });

    test("keeps the values which no environment variable replaces", () async {
      FakeAssets.serve({
        "${_configPath}default.yaml": "logs:\n  level: warning\n  logsNb: 3",
        "${_configPath}env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL",
        "$_configPath.env": "LOGS_LEVEL=trace",
      });
      final manager = _TestConfigManager(logger: const SilentLogger());

      await manager.initLifeCycle();

      expect(manager.logsNb.load(), 3);
    });

    test("gives the default values of the variables when no file exists", () async {
      FakeAssets.serve({});
      final manager = _TestConfigManager(logger: const SilentLogger());

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "info");
      expect(manager.logsNb.load(), isNull);
    });

    test("logs the environment it has been initialized with", () async {
      FakeAssets.serve({});
      final logger = FakeLogger();
      final manager = _TestConfigManager(logger: logger);

      await manager.initLifeCycle();

      expect(logger.recordsAtLevel(LogsLevel.info).length, 1);
      expect(logger.records.first.categories, ["conf"]);
    });
  });

  group("AbstractConfigManager.disposeLifeCycle", () {
    test("releases the configuration, so that a manager can be initialized again", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: warning"});
      final manager = _TestConfigManager(logger: const SilentLogger());
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: error"});
      final other = _TestConfigManager(logger: const SilentLogger());
      await other.initLifeCycle();
      expect(other.logLevel.load(), "error");
    });

    test("accepts to dispose a manager which has never been initialized", () async {
      final manager = _TestConfigManager(logger: const SilentLogger());

      await expectLater(manager.disposeLifeCycle(), completes);
    });
  });

  group("AbstractConfigBuilder", () {
    test("depends on no other manager", () {
      expect(
        _TestConfigBuilder(() => _TestConfigManager(logger: const SilentLogger())).dependsOn(),
        isEmpty,
      );
    });

    test("builds and initializes the manager it is given", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: warning"});

      final manager = await _TestConfigBuilder(
        () => _TestConfigManager(logger: const SilentLogger()),
      ).asyncFactory();

      expect(manager.logLevel.load(), "warning");
    });
  });
}
