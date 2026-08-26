// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_logger_config_manager.dart';

/// Runs [body] and returns the lines it wrote to the console.
List<String> _consoleLines(void Function() body) {
  final lines = <String>[];

  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );

  return lines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLoggerConfigManager config;
  late FlutterExceptionHandler? initialFlutterHandler;

  setUp(() => initialFlutterHandler = FlutterError.onError);

  tearDown(() async {
    FlutterError.onError = initialFlutterHandler;
    await LoggerSingleton.instanceOrNull?.externalLogger.clearExternalLoggers();
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  /// Builds the manager under test, reading the given configuration.
  Future<DefaultLoggerManager> initManager(String content) async {
    config = await FakeLoggerConfigManager.withContent(content);

    final manager = DefaultLoggerManager(loggerConfigGetter: () => config);
    await manager.initLifeCycle();

    return manager;
  }

  group("DefaultLoggerManager", () {
    test("writes the messages to the console", () async {
      final manager = await initManager("logs:\n  level: trace");

      final lines = _consoleLines(() => manager.w("a message"));

      expect(lines.length, 1);
      expect(lines.first, contains("[warn]: a message"));
    });

    test("drops a message below the level of the logs of the configuration", () async {
      final manager = await initManager("logs:\n  level: error");

      final lines = _consoleLines(() => manager.w("a message"));

      expect(lines, isEmpty);
    });

    test("drops a message below the level of the console of the configuration", () async {
      final manager = await initManager(
        "logs:\n  level: trace\n  console:\n    level: error",
      );

      final lines = _consoleLines(() => manager.w("a message"));

      expect(lines, isEmpty);
    });

    test("stops writing to the console once it is disposed", () async {
      final manager = await initManager("logs:\n  level: trace");

      await manager.disposeLifeCycle();

      expect(_consoleLines(() => manager.w("a message")), isEmpty);
    });
  });

  group("DefaultLoggerBuilder", () {
    test("depends on the config manager which holds the level of the logs", () {
      final builder = DefaultLoggerBuilder<FakeLoggerConfigManager>(
        loggerConfigGetter: FakeLoggerConfigManager.new,
      );

      expect(builder.dependsOn(), [FakeLoggerConfigManager]);
    });

    test("builds a manager which writes to the console", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: trace");
      final builder = DefaultLoggerBuilder<FakeLoggerConfigManager>(
        loggerConfigGetter: () => config,
      );

      final manager = await builder.asyncFactory();

      expect(manager, isA<DefaultLoggerManager>());
      expect(_consoleLines(() => manager.w("a message")).length, 1);
    });
  });
}
