// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/loggers/external/multi_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_external_logger.dart';

void main() {
  group("MultiExternalLogger.log", () {
    test("gives the message to every logger it owns", () {
      final first = FakeExternalLogger();
      final second = FakeExternalLogger();
      final logger = MultiExternalLogger(
        externalLoggers: {FakeLoggers.first: first, FakeLoggers.second: second},
      );

      logger.log(message: "a message", level: LogsLevel.warn);

      expect(first.records.length, 1);
      expect(second.records.length, 1);
    });

    test("gives the whole message to the loggers it owns", () {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});
      final stackTrace = StackTrace.fromString("a stack trace");
      final time = DateTime.utc(2025);

      logger.log(
        message: "a message",
        level: LogsLevel.error,
        error: "an error",
        stackTrace: stackTrace,
        categories: ["default"],
        time: time,
      );

      expect(fake.records, [
        FakeExternalLogRecord(
          level: LogsLevel.error,
          message: "a message",
          categories: const ["default"],
          error: "an error",
          stackTrace: stackTrace,
          time: time,
        ),
      ]);
    });

    test("drops a message below its own minimum level", () {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(
        minLevel: LogsLevel.warn,
        externalLoggers: {FakeLoggers.first: fake},
      );

      logger.log(message: "a message", level: LogsLevel.info);

      expect(fake.records, isEmpty);
    });

    test("leaves a logger it owns filter on its own minimum level", () {
      final fake = FakeExternalLogger(minLevel: LogsLevel.error);
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});

      logger.log(message: "a message", level: LogsLevel.info);

      expect(fake.records.length, 1);
    });

    test("accepts to log when it owns no logger", () {
      final logger = MultiExternalLogger();

      expect(() => logger.log(message: "a message", level: LogsLevel.warn), returnsNormally);
    });
  });

  group("MultiExternalLogger.wouldBeLogged", () {
    test("returns true when a logger it owns would log the message", () {
      final logger = MultiExternalLogger(
        externalLoggers: {
          FakeLoggers.first: FakeExternalLogger(minLevel: LogsLevel.error),
          FakeLoggers.second: FakeExternalLogger(minLevel: LogsLevel.info),
        },
      );

      expect(logger.wouldBeLogged(level: LogsLevel.warn), isTrue);
    });

    test("returns false when no logger it owns would log the message", () {
      final logger = MultiExternalLogger(
        externalLoggers: {FakeLoggers.first: FakeExternalLogger(minLevel: LogsLevel.error)},
      );

      expect(logger.wouldBeLogged(level: LogsLevel.warn), isFalse);
    });

    test("returns false for a level below its own minimum level", () {
      final logger = MultiExternalLogger(
        minLevel: LogsLevel.warn,
        externalLoggers: {FakeLoggers.first: FakeExternalLogger()},
      );

      expect(logger.wouldBeLogged(level: LogsLevel.info), isFalse);
    });

    test("returns false when it owns no logger", () {
      expect(MultiExternalLogger().wouldBeLogged(level: LogsLevel.fatal), isFalse);
    });
  });

  group("MultiExternalLogger.initLifeCycle", () {
    test("initializes every logger it owns", () async {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});

      await logger.initLifeCycle();

      expect(fake.initCount, 1);
    });
  });

  group("MultiExternalLogger.addExternalLogger", () {
    test("gives the messages to the logger it adds", () async {
      final logger = MultiExternalLogger();
      final fake = FakeExternalLogger();

      await logger.addExternalLogger(FakeLoggers.first, fake);
      logger.log(message: "a message", level: LogsLevel.warn);

      expect(fake.records.length, 1);
    });

    test("initializes the logger it adds when it is already initialized itself", () async {
      final logger = MultiExternalLogger();
      await logger.initLifeCycle();
      final fake = FakeExternalLogger();

      await logger.addExternalLogger(FakeLoggers.first, fake);

      expect(fake.initCount, 1);
    });

    test("leaves the logger it adds to be initialized with itself", () async {
      final logger = MultiExternalLogger();
      final fake = FakeExternalLogger();

      await logger.addExternalLogger(FakeLoggers.first, fake);

      expect(fake.initCount, 0);
    });

    test("disposes the logger which held the same key", () async {
      final replaced = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: replaced});

      await logger.addExternalLogger(FakeLoggers.first, FakeExternalLogger());

      expect(replaced.disposeCount, 1);
    });

    test("stops giving the messages to the logger it replaced", () async {
      final replaced = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: replaced});

      await logger.addExternalLogger(FakeLoggers.first, FakeExternalLogger());
      logger.log(message: "a message", level: LogsLevel.warn);

      expect(replaced.records, isEmpty);
    });
  });

  group("MultiExternalLogger.removeExternalLogger", () {
    test("disposes the logger it removes", () async {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});

      await logger.removeExternalLogger(FakeLoggers.first);

      expect(fake.disposeCount, 1);
    });

    test("stops giving the messages to the logger it removes", () async {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});

      await logger.removeExternalLogger(FakeLoggers.first);
      logger.log(message: "a message", level: LogsLevel.warn);

      expect(fake.records, isEmpty);
    });

    test("accepts a key it doesn't know", () async {
      final logger = MultiExternalLogger();

      await expectLater(logger.removeExternalLogger(FakeLoggers.first), completes);
    });
  });

  group("MultiExternalLogger.clearExternalLoggers", () {
    test("disposes every logger it owns", () async {
      final first = FakeExternalLogger();
      final second = FakeExternalLogger();
      final logger = MultiExternalLogger(
        externalLoggers: {FakeLoggers.first: first, FakeLoggers.second: second},
      );

      await logger.clearExternalLoggers();

      expect(first.disposeCount, 1);
      expect(second.disposeCount, 1);
    });

    test("owns no logger afterwards", () async {
      final logger = MultiExternalLogger(
        externalLoggers: {FakeLoggers.first: FakeExternalLogger()},
      );

      await logger.clearExternalLoggers();

      expect(logger.wouldBeLogged(level: LogsLevel.fatal), isFalse);
    });
  });

  group("MultiExternalLogger.disposeLifeCycle", () {
    test("disposes every logger it owns", () async {
      final fake = FakeExternalLogger();
      final logger = MultiExternalLogger(externalLoggers: {FakeLoggers.first: fake});

      await logger.disposeLifeCycle();

      expect(fake.disposeCount, 1);
    });
  });

  group("MultiExternalLogger", () {
    test("keeps the loggers it is given rather than the map itself", () {
      final loggers = <Enum, MixinExternalLogger>{FakeLoggers.first: FakeExternalLogger()};
      final logger = MultiExternalLogger(externalLoggers: loggers);

      loggers.clear();

      expect(logger.wouldBeLogged(level: LogsLevel.warn), isTrue);
    });
  });
}
