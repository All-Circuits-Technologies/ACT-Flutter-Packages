// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/loggers/external/multi_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_external_logger.dart';

void main() {
  tearDown(() => LoggerSingleton.instanceOrNull?.externalLogger.clearExternalLoggers());

  group("LoggerSingleton.instance", () {
    // The singleton is never released, so this has to be checked before any other test of this file
    // creates it
    test("throws before the singleton has been created", () {
      expect(LoggerSingleton.instanceOrNull, isNull);
      expect(() => LoggerSingleton.instance, throwsA(isA<ActSingletonNotCreatedError>()));
    });
  });

  group("LoggerSingleton.createInstance", () {
    // The singleton is never released, so only the first call of this file creates it: the loggers
    // and the level it is given are covered here rather than in the tests which follow
    test("owns a logger which writes to all the loggers it is given, at the given level", () {
      final fake = FakeExternalLogger();

      final singleton = LoggerSingleton.createInstance(
        minLevel: LogsLevel.warn,
        externalLoggers: <Enum, MixinExternalLogger>{FakeLoggers.first: fake},
      );
      singleton.externalLogger.log(message: "a message", level: LogsLevel.error);

      expect(singleton.externalLogger.minLevel, LogsLevel.warn);
      expect(fake.records.length, 1);
    });

    test("returns the singleton which already exists rather than another one", () {
      final first = LoggerSingleton.createInstance();
      final level = first.externalLogger.minLevel;

      final second = LoggerSingleton.createInstance(minLevel: LogsLevel.off);

      expect(second, same(first));
      expect(second.externalLogger.minLevel, level);
    });

    test("is the instance the getters return", () {
      final singleton = LoggerSingleton.createInstance();

      expect(LoggerSingleton.instance, same(singleton));
      expect(LoggerSingleton.instanceOrNull, same(singleton));
    });
  });

  group("LoggerSingleton.createOrUpdateInstance", () {
    test("updates the minimum level of the logger of the existing singleton", () {
      final singleton = LoggerSingleton.createInstance(minLevel: LogsLevel.warn);

      LoggerSingleton.createOrUpdateInstance(minLevel: LogsLevel.error);

      expect(singleton.externalLogger.minLevel, LogsLevel.error);
    });

    test("keeps the loggers of the existing singleton", () async {
      final fake = FakeExternalLogger();
      final singleton = LoggerSingleton.createInstance();
      await singleton.externalLogger.addExternalLogger(FakeLoggers.first, fake);

      LoggerSingleton.createOrUpdateInstance(minLevel: LogsLevel.all);
      singleton.externalLogger.log(message: "a message", level: LogsLevel.warn);

      expect(fake.records.length, 1);
    });

    test("returns the same singleton", () {
      final singleton = LoggerSingleton.createInstance();

      expect(LoggerSingleton.createOrUpdateInstance(minLevel: LogsLevel.all), same(singleton));
    });
  });

  group("LoggerSingleton.externalLogger", () {
    test("writes to several loggers at once", () {
      expect(LoggerSingleton.createInstance().externalLogger, isA<MultiExternalLogger>());
    });
  });
}
