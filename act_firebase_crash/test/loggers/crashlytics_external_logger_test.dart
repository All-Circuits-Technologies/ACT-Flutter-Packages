// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_firebase_crash/act_firebase_crash.dart';
import 'package:act_firebase_crash/src/loggers/crashlytics_external_logger.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_crash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCrashlytics crashlytics;

  setUpAll(() async => crashlytics = await FakeCrashlytics.install());

  setUp(() => crashlytics.reset());

  /// Builds the logger of a session which keeps the messages of level [level] and worse.
  CrashlyticsExternalLogger aLogger({required LogsLevel level}) => CrashlyticsExternalLogger(
    crashDebugConfig: FirebaseCrashDebugConfig(identifier: "anId", level: level),
  );

  group("CrashlyticsExternalLogger.minLevel", () {
    test("keeps the messages of the level the session asked for", () {
      final logger = aLogger(level: LogsLevel.info);

      expect(logger.minLevel, LogsLevel.info);
    });

    test("stays on the level of the session when another one is asked for", () {
      final logger = aLogger(level: LogsLevel.info);

      logger.minLevel = LogsLevel.error;

      expect(logger.minLevel, LogsLevel.info);
    });
  });

  group("CrashlyticsExternalLogger.wouldBeLogged", () {
    test("keeps a message of the level of the session", () {
      final logger = aLogger(level: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.warn), isTrue);
    });

    test("keeps a message worse than the level of the session", () {
      final logger = aLogger(level: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.error), isTrue);
    });

    test("drops a message below the level of the session", () {
      final logger = aLogger(level: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.info), isFalse);
    });

    test("keeps a message whatever the categories it belongs to", () {
      final logger = aLogger(level: LogsLevel.warn);

      expect(logger.wouldBeLogged(level: LogsLevel.warn, categories: ["app"]), isTrue);
    });
  });

  group("CrashlyticsExternalLogger.log", () {
    test("writes the message to the console of the session", () async {
      aLogger(level: LogsLevel.warn).log(message: "a message", level: LogsLevel.warn);
      await pumpEventQueue();

      expect(crashlytics.logs, ["a message"]);
    });

    test("names the categories the message belongs to in front of it", () async {
      aLogger(
        level: LogsLevel.warn,
      ).log(message: "a message", level: LogsLevel.warn, categories: ["app", "feature"]);
      await pumpEventQueue();

      expect(crashlytics.logs, ["[app/feature]: a message"]);
    });

    test("writes the error and the stack trace as messages of their own", () async {
      aLogger(level: LogsLevel.warn).log(
        message: "a message",
        level: LogsLevel.error,
        error: "anError",
        stackTrace: StackTrace.fromString("aStackTrace"),
      );
      await pumpEventQueue();

      expect(crashlytics.logs, ["a message", "anError", "aStackTrace"]);
    });

    test("writes nothing for a message below the level of the session", () async {
      aLogger(level: LogsLevel.warn).log(message: "a message", level: LogsLevel.info);
      await pumpEventQueue();

      expect(crashlytics.logs, isEmpty);
    });
  });
}
