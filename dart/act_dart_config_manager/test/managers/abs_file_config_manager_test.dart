// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_config_manager/file_config_loader.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:test/test.dart';

/// A file config manager which declares the variables the tests read.
class _TestFileConfigManager extends AbsFileConfigManager {
  /// The level of the logs, which has a default value.
  final logLevel = const NotNullableConfigVar<String>("logs.level", defaultValue: "info");

  /// The number of log files to keep.
  final logsNb = const ConfigVar<int>("logs.logsNb");

  /// Class constructor
  _TestFileConfigManager({required super.logger, super.configDir, super.env});
}

void main() {
  late Directory directory;

  /// Write [content] to the file named [name] of the config directory.
  void writeFile(String name, String content) {
    File("${directory.path}${Platform.pathSeparator}$name").writeAsStringSync(content);
  }

  /// Create a manager which reads the config directory.
  _TestFileConfigManager createManager({Environment? env = Environment.production}) =>
      _TestFileConfigManager(logger: const SilentLogger(), configDir: directory.path, env: env);

  setUp(() {
    directory = Directory.systemTemp.createTempSync("act_dart_config_manager_test");
  });

  tearDown(() {
    ConfigStore.instanceOrNull?.dispose();
    directory.deleteSync(recursive: true);
  });

  group("AbsFileConfigManager", () {
    test("is a core config manager", () {
      expect(createManager(), isA<AbsCoreConfigManager>());
    });

    test("keeps the directory it is given", () {
      expect(createManager().configDir, directory.path);
    });

    test("keeps the environment it is given", () {
      expect(createManager(env: Environment.qualification).env, Environment.qualification);
    });

    test("resolves the environment from the process when none is given", () {
      expect(createManager(env: null).env, FileConfigLoader.resolveEnvironment());
    });
  });

  group("AbsFileConfigManager.initLifeCycle", () {
    test("makes the values of the configuration files readable", () async {
      writeFile("default.yaml", "logs:\n  level: warning\n  logsNb: 3");
      final manager = createManager();

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "warning");
      expect(manager.logsNb.load(), 3);
    });

    test("reads the file of the chosen environment", () async {
      writeFile("default.yaml", "logs:\n  level: warning");
      writeFile("qualification.yaml", "logs:\n  level: error");
      final manager = createManager(env: Environment.qualification);

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "error");
    });

    test("lets the environment variables override the configuration files", () async {
      writeFile("default.yaml", "logs:\n  level: warning");
      writeFile("env_config_mapping.yaml", "logs:\n  level: ACT_TEST_LOGS_LEVEL");
      writeFile(".env", "ACT_TEST_LOGS_LEVEL=trace");
      final manager = createManager();

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "trace");
    });

    test("gives the default values of the variables when the directory has no file", () async {
      final manager = createManager();

      await manager.initLifeCycle();

      expect(manager.logLevel.load(), "info");
      expect(manager.logsNb.load(), isNull);
    });
  });

  group("AbsFileConfigManager.disposeLifeCycle", () {
    test("releases the configuration", () async {
      writeFile("default.yaml", "logs:\n  level: warning");
      final manager = createManager();
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      expect(ConfigStore.instanceOrNull, isNull);
    });
  });
}
