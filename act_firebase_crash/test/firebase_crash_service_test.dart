// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_crash/act_firebase_crash.dart';
import 'package:act_firebase_crash/src/types/crashlytics_logger_types.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crash.dart';

/// The configuration of an application which says nothing of its crashes.
const _quietConf = "logs:\n  level: trace";

/// The configuration of an application which asks for its crashes to be collected and sent.
const _collectingConf = """
logs:
  level: trace
firebase:
  crash:
    enable: true
    autoLogEnable: true
""";

/// The configuration of an application which refuses to collect its crashes.
const _notCollectingConf = """
logs:
  level: trace
firebase:
  crash:
    enable: false
    autoLogEnable: false
""";

/// The session a test opens to gather the logs of an application.
const _aSession = FirebaseCrashDebugConfig(identifier: "anId");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCrashlytics crashlytics;
  late FakeGlobalManager globalManager;
  late FakeExternalLogger logs;
  late FakeCrashConfig config;
  late FakeLoggerManager loggerManager;
  late FlutterExceptionHandler? initialFlutterHandler;
  late ErrorCallback? initialPlatformHandler;

  setUpAll(() async => crashlytics = await FakeCrashlytics.install());

  setUp(() {
    crashlytics.reset();
    logs = FakeExternalLogger();
    globalManager = FakeGlobalManager.install();
    initialFlutterHandler = FlutterError.onError;
    initialPlatformHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() async {
    FlutterError.onError = initialFlutterHandler;
    PlatformDispatcher.instance.onError = initialPlatformHandler;
    // The loggers live in the logger of the application, which the whole test file shares, so the
    // one a session added has to go before the next test opens another one
    await loggerManager.removeExternalLogger(CrashlyticsLoggerType.crash);
    await globalManager.reset();
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  /// Builds the crash service of an application which reads [content] as its configuration and runs
  /// in the environment [env], and initializes it.
  ///
  /// The service is given [session] to gather the logs of the application from the start when one is
  /// given.
  Future<FirebaseCrashService> aService({
    String content = _quietConf,
    Environment env = Environment.development,
    FirebaseCrashDebugConfig? session,
  }) async {
    config = await FakeCrashConfig.withContent(content, env: env);
    loggerManager = FakeLoggerManager(config: config);
    await loggerManager.initLifeCycle();
    globalManager.managers.registerSingleton<LoggerManager>(loggerManager);

    final service = FirebaseCrashService(confManager: config, crashDebugConfig: session);
    await service.initLifeCycle(parentLogsHelper: logs.buildHelper(category: "firebase"));

    return service;
  }

  /// Reports an error of the platform the way the framework does when nothing caught it.
  void aPlatformError() =>
      PlatformDispatcher.instance.onError!(Exception("a failure"), StackTrace.empty);

  group("FirebaseCrashService.initLifeCycle", () {
    test("leaves the crashes on the device of an application which says nothing of them", () async {
      await aService();

      expect(crashlytics.collectionEnabled, isFalse);
    });

    test("records nothing of an application which says nothing of its crashes", () async {
      await aService();

      aPlatformError();
      await pumpEventQueue();

      expect(crashlytics.errors, isEmpty);
    });

    test("collects the crashes of a production application which says nothing of them", () async {
      await aService(env: Environment.production);

      expect(crashlytics.collectionEnabled, isTrue);
    });

    test("sends the reports of a production application which were left on the device", () async {
      await aService(env: Environment.production);

      expect(crashlytics.sendUnsentReportsCount, 1);
    });

    test(
      "follows the configuration of a production application which refuses to collect",
      () async {
        await aService(content: _notCollectingConf, env: Environment.production);

        expect(crashlytics.collectionEnabled, isFalse);
      },
    );

    test("collects the crashes of an application which asks for it", () async {
      await aService(content: _collectingConf);

      expect(crashlytics.collectionEnabled, isTrue);
    });

    test("records the errors of the platform as fatal ones", () async {
      await aService(content: _collectingConf);

      aPlatformError();
      await pumpEventQueue();

      expect(crashlytics.errors, [(exception: "Exception: a failure", fatal: true)]);
    });

    test("records the errors of Flutter which nothing caught", () async {
      await aService(content: _collectingConf);

      FlutterError.onError!(FlutterErrorDetails(exception: Exception("a failure")));
      await pumpEventQueue();

      expect(crashlytics.errors, isNotEmpty);
    });

    test("names the session it is given to gather the logs of the application", () async {
      await aService(session: _aSession);

      expect(crashlytics.identifiers, ["anId"]);
    });

    test("writes the logs of the application to the session it is given", () async {
      await aService(session: _aSession);

      loggerManager.w("a message");
      await pumpEventQueue();

      expect(crashlytics.logs.single, endsWith("a message"));
    });
  });

  group("FirebaseCrashService.setEnableDataCollection", () {
    test("records the errors of the platform once the collection is turned on", () async {
      final service = await aService();

      await service.setEnableDataCollection(true);
      aPlatformError();
      await pumpEventQueue();

      expect(crashlytics.errors, [(exception: "Exception: a failure", fatal: true)]);
    });

    test("stops recording the errors of the platform once the collection is turned off", () async {
      final service = await aService(content: _collectingConf);

      await service.setEnableDataCollection(false);
      aPlatformError();
      await pumpEventQueue();

      expect(crashlytics.errors, isEmpty);
    });

    test("drops the reports left on the device once the collection is turned off", () async {
      final service = await aService(content: _collectingConf);

      await service.setEnableDataCollection(false);

      expect(crashlytics.deleteUnsentReportsCount, 1);
    });

    test("leaves the device alone when the collection is already in the asked state", () async {
      final service = await aService();

      await service.setEnableDataCollection(false);

      expect(crashlytics.deleteUnsentReportsCount, 0);
    });
  });

  group("FirebaseCrashService.setEnableAutoDataCollection", () {
    test("tells the device to collect once the automatic sending is turned on", () async {
      final service = await aService();

      await service.setEnableAutoDataCollection(true);

      expect(crashlytics.collectionEnabled, isTrue);
    });

    test("sends the reports left on the device once the automatic sending is on", () async {
      final service = await aService();

      await service.setEnableAutoDataCollection(true);

      expect(crashlytics.sendUnsentReportsCount, 1);
    });

    test("tells the device to stop collecting once the automatic sending is off", () async {
      final service = await aService(content: _collectingConf);

      await service.setEnableAutoDataCollection(false);

      expect(crashlytics.collectionEnabled, isFalse);
    });

    test("leaves the device alone when the sending is already in the asked state", () async {
      final service = await aService();

      await service.setEnableAutoDataCollection(false);

      expect(crashlytics.sendUnsentReportsCount, 0);
    });
  });

  group("FirebaseCrashService reports left on the device", () {
    test("sends the reports the device kept", () async {
      final service = await aService();

      await service.sendUnsentReports();

      expect(crashlytics.sendUnsentReportsCount, 1);
    });

    test("drops the reports the device kept", () async {
      final service = await aService();

      await service.deleteUnsentReports();

      expect(crashlytics.deleteUnsentReportsCount, 1);
    });

    test("tells whether the device kept reports which were not sent", () async {
      final service = await aService();
      crashlytics.unsentReports = true;

      expect(await service.checkForUnsentReports(), isTrue);
    });

    test("tells whether the application crashed the last time it ran", () async {
      final service = await aService();
      crashlytics.crashedOnPreviousExecution = true;

      expect(await service.didCrashOnPreviousExecution(), isTrue);
    });
  });

  group("FirebaseCrashService.sendCrashDebugReport", () {
    test("records the session the logs belong to, which is what sends them", () async {
      final service = await aService(session: _aSession);

      await service.sendCrashDebugReport();

      expect(crashlytics.errors.single.exception, contains("identifier: anId"));
    });

    test("answers that the report of the session was recorded", () async {
      final service = await aService(session: _aSession);

      expect(await service.sendCrashDebugReport(), isTrue);
    });

    test("records nothing when no session was opened", () async {
      final service = await aService();

      await service.sendCrashDebugReport();

      expect(crashlytics.errors, isEmpty);
    });

    test("answers that nothing was recorded when no session was opened", () async {
      final service = await aService();

      expect(await service.sendCrashDebugReport(), isFalse);
    });

    test("warns under the logs it hangs from that no session was opened", () async {
      final service = await aService();

      await service.sendCrashDebugReport();

      expect(logs.recordsAtLevel(LogsLevel.warn).single.categories, ["firebase", "crashlytics"]);
    });
  });

  group("FirebaseCrashService.setCrashDebugConfig", () {
    test("names the session the logs are gathered for", () async {
      final service = await aService();

      await service.setCrashDebugConfig(_aSession);

      expect(crashlytics.identifiers, ["anId"]);
    });

    test("writes the logs of the application to the session which was opened", () async {
      final service = await aService();

      await service.setCrashDebugConfig(_aSession);
      loggerManager.w("a message");
      await pumpEventQueue();

      expect(crashlytics.logs.single, endsWith("a message"));
    });

    test("forgets the user of the application once the session is closed", () async {
      final service = await aService(session: _aSession);

      await service.setCrashDebugConfig(null);

      expect(crashlytics.identifiers, ["anId", ""]);
    });

    test("stops writing the logs of the application once the session is closed", () async {
      final service = await aService(session: _aSession);

      await service.setCrashDebugConfig(null);
      loggerManager.w("a message");
      await pumpEventQueue();

      expect(crashlytics.logs, isEmpty);
    });

    test("leaves the device alone when no session was opened and none is asked for", () async {
      final service = await aService();

      await service.setCrashDebugConfig(null);

      expect(crashlytics.identifiers, isEmpty);
    });

    test("leaves the device alone when the session which is asked for is the open one", () async {
      final service = await aService(session: _aSession);

      await service.setCrashDebugConfig(_aSession);

      expect(crashlytics.identifiers, ["anId"]);
    });

    test("keeps the logs of the level of the session which takes over", () async {
      final service = await aService(
        session: const FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.error),
      );

      await service.setCrashDebugConfig(
        const FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.info),
      );
      loggerManager.i("a message");
      await pumpEventQueue();

      expect(crashlytics.logs.single, endsWith("a message"));
    });
  });
}
