// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';
import 'package:act_logger_manager/src/types/safe_external_loggers.dart';
// The external logger this package defines is the one under test, so its own fake is the one to
// drive here, not the shared one which stands in for it elsewhere
import 'package:act_test_utility/act_test_utility.dart' hide FakeExternalLogger;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_external_logger.dart';
import '../fakes/fake_logger_config_manager.dart';

/// A logger manager which replaces the safe logger with the loggers it is given.
class _TestLoggerManager extends LoggerManager {
  /// The loggers which replace the safe one when the manager is initialized.
  final Map<Enum, MixinExternalLogger> replacements;

  /// Class constructor
  _TestLoggerManager({required super.loggerConfigGetter, this.replacements = const {}});

  /// {@macro act_logger_manager.LoggerManager.buildExternalLoggersToReplaceSafeLogger}
  @override
  Future<Map<Enum, MixinExternalLogger>> buildExternalLoggersToReplaceSafeLogger() async =>
      replacements;
}

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
  late FakeExternalLogger fake;
  late FlutterExceptionHandler? initialFlutterHandler;
  late ErrorCallback? initialPlatformHandler;

  setUp(() {
    fake = FakeExternalLogger();
    initialFlutterHandler = FlutterError.onError;
    initialPlatformHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() async {
    FlutterError.onError = initialFlutterHandler;
    PlatformDispatcher.instance.onError = initialPlatformHandler;
    await LoggerSingleton.instanceOrNull?.externalLogger.clearExternalLoggers();
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  /// Builds a manager which reads the level [level] from its configuration and which registers the
  /// fake logger of the test in place of the safe one.
  Future<_TestLoggerManager> initManager({String level = "trace"}) async {
    config = await FakeLoggerConfigManager.withContent("logs:\n  level: $level");

    final manager = _TestLoggerManager(
      loggerConfigGetter: () => config,
      replacements: {FakeLoggers.first: fake},
    );
    await manager.initLifeCycle();

    return manager;
  }

  group("LoggerManager.initLifeCycle", () {
    test("takes the minimum level of the logs from the configuration", () async {
      await initManager(level: "error");

      expect(LoggerSingleton.instance.externalLogger.minLevel, LogsLevel.error);
    });

    test("initializes the loggers it registers", () async {
      await initManager();

      expect(fake.initCount, 1);
    });

    test("writes the messages of the manager to the loggers it registers", () async {
      final manager = await initManager();

      manager.w("a message");

      expect(fake.records.length, 1);
      expect(fake.records.first.level, LogsLevel.warn);
    });

    test("removes the safe logger once its own loggers are registered", () async {
      await LoggerSingleton.createInstance().externalLogger.addExternalLogger(
        SafeExternalLoggers.console,
        ConsoleExternalLogger.withMinLevel(),
      );
      final manager = await initManager();

      final lines = _consoleLines(() => manager.w("a message"));

      expect(lines, isEmpty);
      expect(fake.records.length, 1);
    });

    test("keeps the safe logger when it registers no logger of its own", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: trace");
      await LoggerSingleton.createInstance().externalLogger.addExternalLogger(
        SafeExternalLoggers.console,
        ConsoleExternalLogger.withMinLevel(),
      );
      final manager = _TestLoggerManager(loggerConfigGetter: () => config);
      await manager.initLifeCycle();

      final lines = _consoleLines(() => manager.w("a message"));

      expect(lines.length, 1);
    });
  });

  group("LoggerManager", () {
    test("logs at the level of the method which is called", () async {
      final manager = await initManager();

      manager
        ..t("trace")
        ..d("debug")
        ..i("info")
        ..w("warn")
        ..e("error")
        ..f("fatal");

      expect(fake.records.map((record) => record.level), [
        LogsLevel.trace,
        LogsLevel.debug,
        LogsLevel.info,
        LogsLevel.warn,
        LogsLevel.error,
        LogsLevel.fatal,
      ]);
    });

    test("logs a message of an unknown level at the default one", () async {
      final manager = await initManager();

      manager.logMessages("a message");

      expect(fake.records.first.level, LogsLevel.debug);
    });

    test("gives its sub category to the messages of a sub logger", () async {
      final manager = await initManager();

      manager.createAbsSubLogger(subCategory: "http").w("a message");

      expect(fake.records.first.categories, ["http"]);
    });

    test("lets a sub logger raise the minimum level of its messages", () async {
      final manager = await initManager();

      manager
          .createAbsSubLoggerMinLevel(subCategory: "http", minLevel: LogsLevel.error)
          .w("a message");

      expect(fake.records, isEmpty);
    });

    test("reports whether a message would be logged", () async {
      final manager = await initManager(level: "error");

      expect(manager.wouldBeLogged(LogsLevel.error), isTrue);
      expect(manager.wouldBeLogged(LogsLevel.info), isFalse);
    });
  });

  group("LoggerManager.addExternalLogger", () {
    test("writes the messages to the logger it adds", () async {
      final manager = await initManager();
      final added = FakeExternalLogger();

      await manager.addExternalLogger(FakeLoggers.second, added);
      manager.w("a message");

      expect(added.records.length, 1);
    });
  });

  group("LoggerManager.removeExternalLogger", () {
    test("stops writing the messages to the logger it removes", () async {
      final manager = await initManager();

      await manager.removeExternalLogger(FakeLoggers.first);
      manager.w("a message");

      expect(fake.records, isEmpty);
      expect(fake.disposeCount, 1);
    });
  });

  group("LoggerManager and the errors of the framework", () {
    test("logs the errors of the framework", () async {
      final manager = await initManager();

      FlutterError.onError!(FlutterErrorDetails(exception: Exception("a failure")));

      expect(fake.records.length, 1);
      expect(fake.records.first.level, LogsLevel.error);
      expect(manager.wouldBeLogged(LogsLevel.error), isTrue);
    });

    test("gives the errors of the framework to the handlers it is given", () async {
      final manager = await initManager();
      final handled = <FlutterErrorDetails>[];
      manager.addFlutterExceptionHandler(handled.add);

      FlutterError.onError!(FlutterErrorDetails(exception: Exception("a failure")));

      expect(handled.length, 1);
    });

    test("stops giving the errors to a handler which has been removed", () async {
      final manager = await initManager();
      final handled = <FlutterErrorDetails>[];
      manager
        ..addFlutterExceptionHandler(handled.add)
        ..removeFlutterExceptionHandler(handled.add);

      FlutterError.onError!(FlutterErrorDetails(exception: Exception("a failure")));

      expect(handled, isEmpty);
    });

    test("logs the errors of the platform and reports them as handled", () async {
      await initManager();

      final handled = PlatformDispatcher.instance.onError!(
        Exception("a failure"),
        StackTrace.empty,
      );

      expect(handled, isTrue);
      expect(fake.records.length, 1);
      expect(fake.records.first.level, LogsLevel.error);
    });

    test("gives the errors of the platform to the callbacks it is given", () async {
      final manager = await initManager();
      final handled = <Object>[];
      manager.addPlatformErrorCallback((exception, stackTrace) => handled.add(exception));

      PlatformDispatcher.instance.onError!(Exception("a failure"), StackTrace.empty);

      expect(handled.length, 1);
    });

    test("stops giving the errors to a callback which has been removed", () async {
      final manager = await initManager();
      final handled = <Object>[];
      void callback(Object exception, StackTrace stackTrace) => handled.add(exception);
      manager
        ..addPlatformErrorCallback(callback)
        ..removePlatformErrorCallback(callback);

      PlatformDispatcher.instance.onError!(Exception("a failure"), StackTrace.empty);

      expect(handled, isEmpty);
    });
  });

  group("LoggerManager.getSafeLogger", () {
    test("gives a logger which is ready before any manager is initialized", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: trace");

      expect(LoggerManager.getSafeLogger(), isA<MixinActLogger>());
    });

    test("writes to the console", () async {
      config = await FakeLoggerConfigManager.withContent("logs:\n  level: trace");
      await LoggerSingleton.createInstance().externalLogger.addExternalLogger(
        SafeExternalLoggers.console,
        ConsoleExternalLogger.withMinLevel(),
      );
      final logger = LoggerManager.getSafeLogger();

      final lines = _consoleLines(() => logger.e("a message"));

      expect(lines.length, 1);
    });
  });

  group("LoggerManager.disposeLifeCycle", () {
    test("disposes the loggers it registered", () async {
      final manager = await initManager();

      await manager.disposeLifeCycle();

      expect(fake.disposeCount, 1);
    });
  });
}
