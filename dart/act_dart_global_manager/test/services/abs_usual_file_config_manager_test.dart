// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_config_manager/file_config_loader.dart';
import 'package:act_dart_global_manager/usual_file_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:test/test.dart';

/// The usual file config manager of an application, which doesn't declare any variable of its own.
class _TestUsualFileConfigManager extends AbsUsualFileConfigManager {
  /// Class constructor
  _TestUsualFileConfigManager({super.configDir, super.env}) : super(logger: const SilentLogger());
}

void main() {
  late Directory directory;

  /// Write [content] to the file named [name] of the config directory.
  void writeFile(String name, String content) {
    File("${directory.path}${Platform.pathSeparator}$name").writeAsStringSync(content);
  }

  /// Create a manager which reads the config directory.
  _TestUsualFileConfigManager createManager() =>
      _TestUsualFileConfigManager(configDir: directory.path, env: Environment.production);

  setUp(() {
    directory = Directory.systemTemp.createTempSync("act_dart_global_manager_test");
  });

  tearDown(() {
    ConfigStore.instanceOrNull?.dispose();
    directory.deleteSync(recursive: true);
  });

  group("AbsUsualFileConfigManager", () {
    test("is a file config manager", () {
      expect(createManager(), isA<AbsFileConfigManager>());
    });

    test("declares the config variables of the loggers", () {
      final manager = createManager();

      expect(manager, isA<MixinLoggerConfig>());
      expect(manager, isA<MixinCslLoggerConfig>());
      expect(manager, isA<MixinDefaultLoggerConfig>());
    });

    test("keeps the directory and the environment it is given", () {
      final manager = createManager();

      expect(manager.configDir, directory.path);
      expect(manager.env, Environment.production);
    });

    test("reads the level of the logs from the config directory", () async {
      writeFile("default.yaml", "logs:\n  level: trace\n");
      final manager = createManager();

      await manager.initLifeCycle();

      expect(manager.logLevelEnv.load(), LogsLevel.trace);

      await manager.disposeLifeCycle();
    });
  });
}
