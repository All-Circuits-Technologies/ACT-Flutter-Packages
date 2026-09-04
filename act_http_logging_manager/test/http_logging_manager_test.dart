// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The logging manager of an application which names the source of its logs.
class _SourcedLoggingManager extends HttpLoggingManager {
  /// {@macro act_http_logging_manager.HttpLoggingManager.getSourceInfo}
  @override
  Future<String?> getSourceInfo() async => "server";
}

/// The builder of the logging manager of an application which names its source.
class _SourcedLoggingBuilder extends AbsHttpLoggingBuilder<_SourcedLoggingManager> {
  /// Class constructor
  const _SourcedLoggingBuilder() : super(_SourcedLoggingManager.new);
}

/// Builds the log of a request the application made.
HttpLog aLog({LogsLevel level = LogsLevel.info}) => HttpLog(
  timestamp: DateTime.utc(2024, 5, 17, 10, 30),
  requestId: "req-1",
  route: "/devices",
  method: "GET",
  logLevel: level,
  message: "the request went well",
);

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("HttpLoggingBuilder", () {
    test("depends on the logger manager", () {
      expect(const HttpLoggingBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds a logging manager", () {
      expect(const HttpLoggingBuilder().factory(), isA<HttpLoggingManager>());
    });
  });

  group("HttpLoggingManager", () {
    test("names no source unless the application gives one", () async {
      final manager = HttpLoggingManager();

      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      expect(manager.sourceInfo, isNull);
    });

    test("reads the source the application gives", () async {
      final manager = _SourcedLoggingManager();

      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      expect(manager.sourceInfo, "server");
    });
  });

  group("HttpLoggingManager.addLog", () {
    test("pushes the log on the stream the application listens to", () async {
      final manager = HttpLoggingManager();
      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);
      final pushed = expectLater(manager.logStream, emits(aLog()));

      manager.addLog(aLog());

      await pushed;
    });

    test("writes the log where the application writes its own", () async {
      final manager = HttpLoggingManager();
      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      manager.addLog(aLog());

      expect(
        logger.records.single.message,
        "[req-1] - /devices - GET - the request went well",
      );
    });

    test("writes the log at the level it carries", () async {
      final manager = HttpLoggingManager();
      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      manager.addLog(aLog(level: LogsLevel.error));

      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });

    test("adds the source of the application to a log which carries none", () async {
      final manager = _SourcedLoggingManager();
      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);
      final pushed = expectLater(
        manager.logStream,
        emits(isA<HttpLog>().having((log) => log.sourceInfo, "sourceInfo", "server")),
      );

      manager.addLog(aLog());

      await pushed;
    });

    test("writes the source in the message it logs", () async {
      final manager = _SourcedLoggingManager();
      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      manager.addLog(aLog());

      expect(
        logger.records.single.message,
        "[server/req-1] - /devices - GET - the request went well",
      );
    });
  });

  group("AbsHttpLoggingBuilder", () {
    test("depends on the logger manager, whatever the manager it builds", () {
      expect(const _SourcedLoggingBuilder().dependsOn(), [LoggerManager]);
    });
  });

  group("HttpLoggingManager.disposeLifeCycle", () {
    test("closes the stream the application listens to", () async {
      final manager = HttpLoggingManager();
      await manager.initLifeCycle();
      final done = expectLater(manager.logStream, emitsDone);

      await manager.disposeLifeCycle();

      await done;
    });
  });
}
