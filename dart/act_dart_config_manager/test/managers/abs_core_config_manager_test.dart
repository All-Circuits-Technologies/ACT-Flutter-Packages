// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_life_cycle/act_dart_life_cycle.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// A config manager which gets its configuration from a map given at construction.
class _FakeConfigManager extends AbsCoreConfigManager {
  /// The level of the logs, which has a default value.
  final logLevel = const NotNullableConfigVar<String>("logs.level", defaultValue: "info");

  /// The number of log files to keep.
  final logsNb = const ConfigVar<int>("logs.logsNb");

  /// The configuration [loadConfigs] returns.
  final Map<String, dynamic> configs;

  /// The number of times [loadConfigs] has been called.
  int loadCount = 0;

  /// Class constructor
  _FakeConfigManager({
    required super.logger,
    this.configs = const {},
    super.env = Environment.production,
  });

  /// Give the configuration of the manager and count the call.
  @override
  @protected
  Future<Map<String, dynamic>> loadConfigs() async {
    loadCount++;
    return configs;
  }
}

/// A builder of the manager the tests use.
class _FakeConfigBuilder extends AbsCoreConfigBuilder<_FakeConfigManager> {
  /// Class constructor
  _FakeConfigBuilder(super.factory);
}

void main() {
  tearDown(() {
    ConfigStore.instanceOrNull?.dispose();
  });

  group("AbsCoreConfigManager", () {
    test("is a manager with a life cycle", () {
      expect(_FakeConfigManager(logger: const SilentLogger()), isA<AbsWithLifeCycle>());
    });

    test("keeps the environment it is given", () {
      final manager = _FakeConfigManager(logger: const SilentLogger(), env: Environment.local);

      expect(manager.env, Environment.local);
    });

    test("doesn't load the configuration before it is initialized", () {
      final manager = _FakeConfigManager(logger: const SilentLogger());

      expect(manager.loadCount, 0);
      expect(ConfigStore.instanceOrNull, isNull);
    });
  });

  group("AbsCoreConfigManager.initLifeCycle", () {
    test("makes the values returned by loadConfigs readable", () async {
      final manager = _FakeConfigManager(
        logger: const SilentLogger(),
        configs: {
          "logs": {"level": "warning", "logsNb": 3},
        },
      );

      await manager.initLifeCycle();

      expect(manager.loadCount, 1);
      expect(manager.logLevel.load(), "warning");
      expect(manager.logsNb.load(), 3);
    });

    test("gives the default values of the variables when the configuration is empty", () async {
      final manager = _FakeConfigManager(logger: const SilentLogger());

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "info");
      expect(manager.logsNb.load(), isNull);
    });

    test("logs the environment it has been initialized with, under its own category", () async {
      final logger = FakeLogger();
      final manager = _FakeConfigManager(logger: logger, env: Environment.qualification);

      await manager.initLifeCycle();

      expect(logger.recordsAtLevel(LogsLevel.info).length, 1);
      expect(logger.records.first.categories, ["conf"]);
      expect(
        logger.records.first.message.toString(),
        contains(Environment.qualification.toString()),
      );
    });
  });

  group("AbsCoreConfigManager.disposeLifeCycle", () {
    test("releases the configuration, so that a manager can be initialized again", () async {
      final manager = _FakeConfigManager(
        logger: const SilentLogger(),
        configs: {
          "logs": {"level": "warning"},
        },
      );
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      final other = _FakeConfigManager(
        logger: const SilentLogger(),
        configs: {
          "logs": {"level": "error"},
        },
      );
      await other.initLifeCycle();
      expect(other.logLevel.load(), "error");
    });

    test("accepts to dispose a manager which has never been initialized", () async {
      final manager = _FakeConfigManager(logger: const SilentLogger());

      await expectLater(manager.disposeLifeCycle(), completes);
    });
  });

  group("AbsCoreConfigBuilder", () {
    test("depends on no other manager", () {
      expect(
        _FakeConfigBuilder(() => _FakeConfigManager(logger: const SilentLogger())).dependsOn(),
        isEmpty,
      );
    });

    test("builds and initializes the manager it is given", () async {
      final manager = await _FakeConfigBuilder(
        () => _FakeConfigManager(
          logger: const SilentLogger(),
          configs: {
            "logs": {"level": "warning"},
          },
        ),
      ).asyncFactory();

      expect(manager.logLevel.load(), "warning");
    });
  });
}
