// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'fakes/fake_server.dart';

/// The host the servers of the tests answer on.
const _host = "127.0.0.1";

/// The port a server is asked to take, which lets the machine give it a free one.
const _anyPort = 0;

/// The port the server took, read from the log it wrote when it started.
///
/// The manager keeps the server to itself, so the address it bound to is only known from what it
/// wrote.
int _portOf(FakeHttpLogging logging) {
  final started = logging.messages.firstWhere((message) => message.contains("started on"));

  return int.parse(started.split(":").last);
}

void main() {
  late FakeHttpLogging logging;
  late FakeApiService service;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
  });

  /// Starts the server of an application, on a port the machine chooses.
  Future<FakeHttpServerManager> aServer({
    List<AbsServerHandler>? globalHandlers,
    String? basePath,
  }) async {
    final config = HttpServerConfig(
      serverName: "a server",
      hostname: _host,
      port: _anyPort,
      basePath: basePath,
    );
    service = FakeApiService(httpLoggingManager: logging, config: config);

    final manager = FakeHttpServerManager(
      serverConfig: config,
      logging: logging,
      services: [service],
      globalHandlers: globalHandlers,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  /// Asks [path] of the server which wrote to [logging].
  Future<http.Response> ask(String path) =>
      http.get(Uri.parse("http://$_host:${_portOf(logging)}$path"));

  group("AbsHttpServerBuilder", () {
    test("depends on the logger manager and on the logging of the requests", () {
      final builder = FakeHttpServerBuilder(
        () => FakeHttpServerManager(
          serverConfig: const HttpServerConfig(
            serverName: "a server",
            hostname: _host,
            port: _anyPort,
          ),
          logging: logging,
          services: const [],
        ),
      );

      expect(builder.dependsOn(), [LoggerManager, HttpLoggingManager]);
    });
  });

  group("AbsHttpServerManager.initLifeCycle", () {
    test("writes that the server started, with the address it answers on", () async {
      await aServer();

      expect(logging.messages.first, startsWith("Server: a server started on $_host:"));
    });

    test("initializes every service of the application", () async {
      await aServer();

      expect(service.initCount, 1);
    });

    test("keeps the services of the application", () async {
      final manager = await aServer();

      expect(manager.apiServices, [service]);
    });

    test("answers on the routes of its services", () async {
      await aServer();

      final response = await ask("/hello");

      expect(response.statusCode, 200);
      expect(response.body, "hello");
    });

    test("answers on the routes under the base path of the server", () async {
      await aServer(basePath: "/api");

      expect((await ask("/api/hello")).statusCode, 200);
      expect((await ask("/hello")).statusCode, 404);
    });

    test("turns away a request for a route no service answers on", () async {
      await aServer();

      expect((await ask("/nothing")).statusCode, 404);
    });

    test("writes that it did not find the route of a request it turned away", () async {
      await aServer();

      await ask("/nothing");

      expect(logging.messages, contains("The route isn't found"));
    });

    test("marks every request it receives with an identifier of its own", () async {
      await aServer();

      await ask("/hello");

      expect(logging.messages, contains("Received request"));
      expect(logging.messages, contains("Responded with status code 200"));
    });

    test("calls the handlers the application gave it instead of the ones it has", () async {
      final calls = <String>[];
      await aServer(
        globalHandlers: [FakeServerHandler(httpLoggingManager: logging, calls: calls)],
      );

      await ask("/hello");

      expect(calls, ["a handler.before", "a handler.after"]);
      expect(logging.messages, isNot(contains("Received request")));
    });
  });

  group("AbsHttpServerManager.disposeLifeCycle", () {
    test("stops answering", () async {
      final manager = await aServer();
      final port = _portOf(logging);

      await manager.disposeLifeCycle();

      await expectLater(
        http.get(Uri.parse("http://$_host:$port/hello")),
        throwsA(isA<Exception>()),
      );
    });

    test("writes that the server closed", () async {
      final manager = await aServer();

      await manager.disposeLifeCycle();

      expect(logging.messages.last, startsWith("Server closed on $_host:"));
    });

    test("disposes every service of the application", () async {
      final manager = await aServer();

      await manager.disposeLifeCycle();

      expect(service.disposeCount, 1);
    });

    test("disposes the handlers of the server", () async {
      final calls = <String>[];
      final manager = await aServer(
        globalHandlers: [FakeServerHandler(httpLoggingManager: logging, calls: calls)],
      );

      await manager.disposeLifeCycle();

      expect(calls, contains("a handler.dispose"));
    });
  });
}
