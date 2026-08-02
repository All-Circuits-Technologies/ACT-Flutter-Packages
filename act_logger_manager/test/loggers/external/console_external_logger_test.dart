// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_logger_config_manager.dart';

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

  tearDown(FakeAssets.stop);

  group("ConsoleExternalLogger.withMinLevel", () {
    test("keeps every message by default", () {
      expect(ConsoleExternalLogger.withMinLevel().minLevel, LogsLevel.all);
    });

    test("keeps the minimum level it is given", () {
      expect(
        ConsoleExternalLogger.withMinLevel(minLevel: LogsLevel.warn).minLevel,
        LogsLevel.warn,
      );
    });
  });

  group("ConsoleExternalLogger.fromConfigGetter", () {
    test("logs nothing before it is initialized", () {
      final logger = ConsoleExternalLogger.fromConfigGetter(
        configGetter: FakeLoggerConfigManager.new,
      );

      expect(logger.minLevel, LogsLevel.off);
    });

    test("takes its minimum level from the configuration when it is initialized", () async {
      final config = await FakeLoggerConfigManager.withContent(
        "logs:\n  console:\n    level: warning",
      );
      final logger = ConsoleExternalLogger.fromConfigGetter(configGetter: () => config);

      await logger.initLifeCycle();

      expect(logger.minLevel, LogsLevel.warn);

      await logger.disposeLifeCycle();
      await config.disposeLifeCycle();
    });

    test("takes the printing in release from the configuration", () async {
      final config = await FakeLoggerConfigManager.withContent(
        "logs:\n  console:\n    printInRelease: true",
      );
      final logger = ConsoleExternalLogger.fromConfigGetter(configGetter: () => config);

      await logger.initLifeCycle();

      expect(logger.printLogInRelease, isTrue);

      await logger.disposeLifeCycle();
      await config.disposeLifeCycle();
    });

    test("keeps every message when the configuration gives no level", () async {
      final config = await FakeLoggerConfigManager.withContent("logs:\n  level: warning");
      final logger = ConsoleExternalLogger.fromConfigGetter(configGetter: () => config);

      await logger.initLifeCycle();

      expect(logger.minLevel, LogsLevel.all);

      await logger.disposeLifeCycle();
      await config.disposeLifeCycle();
    });
  });

  group("ConsoleExternalLogger.log", () {
    test("writes the message to the console", () {
      final logger = ConsoleExternalLogger.withMinLevel();

      final lines = _consoleLines(
        () => logger.log(
          message: "a message",
          level: LogsLevel.warn,
          categories: ["manager"],
          time: DateTime.utc(2025),
        ),
      );

      expect(lines, ["2025-01-01T00:00:00.000Z-[warn][manager]: a message"]);
    });

    test("writes the error and the stack trace after the message", () {
      final logger = ConsoleExternalLogger.withMinLevel();

      final lines = _consoleLines(
        () => logger.log(
          message: "a message",
          level: LogsLevel.error,
          error: "an error",
          stackTrace: StackTrace.fromString("a stack trace"),
          time: DateTime.utc(2025),
        ),
      );

      expect(lines, [
        "2025-01-01T00:00:00.000Z-[error]: a message",
        "2025-01-01T00:00:00.000Z-[error]: an error",
        "2025-01-01T00:00:00.000Z-[error]: a stack trace",
      ]);
    });

    test("writes nothing for a message below its minimum level", () {
      final logger = ConsoleExternalLogger.withMinLevel(minLevel: LogsLevel.error);

      final lines = _consoleLines(
        () => logger.log(message: "a message", level: LogsLevel.info),
      );

      expect(lines, isEmpty);
    });
  });

  group("ConsoleExternalLogger.wouldBeLogged", () {
    test("returns true for a message of its minimum level", () {
      final logger = ConsoleExternalLogger.withMinLevel(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.warn), isTrue);
    });

    test("returns false for a message below its minimum level", () {
      final logger = ConsoleExternalLogger.withMinLevel(minLevel: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.debug), isFalse);
    });

    test("follows the minimum level it has been set to", () {
      final logger = ConsoleExternalLogger.withMinLevel(minLevel: LogsLevel.warn)
        ..minLevel = LogsLevel.debug;

      expect(logger.wouldBeLogged(level: LogsLevel.debug), isTrue);
    });
  });

  group("ConsoleExternalLogger.disposeLifeCycle", () {
    test("stops writing to the console", () async {
      final logger = ConsoleExternalLogger.withMinLevel();

      await logger.disposeLifeCycle();

      expect(
        () => logger.log(message: "a message", level: LogsLevel.warn),
        throwsArgumentError,
      );
    });
  });
}
