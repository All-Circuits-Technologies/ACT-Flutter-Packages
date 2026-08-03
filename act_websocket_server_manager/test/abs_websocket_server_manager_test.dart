// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_websocket_server_manager/act_websocket_server_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_ws_server.dart';

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

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
  });

  /// Starts the WebSocket server of an application, on a port the machine chooses.
  Future<FakeWsServerManager> aServer({
    required AbsWebsocketApiService service,
    String? basePath,
  }) async {
    final manager = FakeWsServerManager(
      serverConfig: HttpServerConfig(
        serverName: "a server",
        hostname: _host,
        port: _anyPort,
        basePath: basePath,
      ),
      logging: logging,
      service: service,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  /// The service which answers on the WebSocket of the server of the test.
  ///
  /// A service reads the base path of the server from the configuration it is given, which is the
  /// one the manager hands it in an application.
  FakeWsApiService aService({
    String? relativePath,
    String? basePath,
    WebsocketServerConfig? websocketConfig,
  }) => FakeWsApiService(
    httpLoggingManager: logging,
    config: HttpServerConfig(
      serverName: "a server",
      hostname: _host,
      port: _anyPort,
      basePath: basePath,
    ),
    serviceRelativePath: relativePath,
    websocketConfig: websocketConfig,
  );

  /// Connects a client to the server which wrote to [logging], on [path].
  Future<WebSocketChannel> aClient({String path = "", List<String>? protocols}) async {
    final client = WebSocketChannel.connect(
      Uri.parse("ws://$_host:${_portOf(logging)}$path"),
      protocols: protocols,
    );
    await client.ready;
    addTearDown(() => client.sink.close());

    return client;
  }

  group("AbsWebsocketServerBuilder", () {
    test("depends on the logger manager and on the logging of the requests", () {
      final builder = FakeWsServerBuilder(
        () => FakeWsServerManager(
          serverConfig: const HttpServerConfig(
            serverName: "a server",
            hostname: _host,
            port: _anyPort,
          ),
          logging: logging,
          service: aService(),
        ),
      );

      expect(builder.dependsOn(), [LoggerManager, HttpLoggingManager]);
    });
  });

  group("AbsWebsocketServerManager.initLifeCycle", () {
    test("answers on the route of its WebSocket service", () async {
      final service = aService();
      await aServer(service: service);

      await aClient();

      expect(service.channelServices, hasLength(1));
    });

    test("answers on the route the service of the application names", () async {
      final service = aService(relativePath: "events");
      await aServer(service: service);

      await aClient(path: "/events");

      expect(service.channelServices, hasLength(1));
    });

    test("answers under the base path of the server", () async {
      final service = aService(relativePath: "events", basePath: "/api");
      await aServer(service: service, basePath: "/api");

      await aClient(path: "/api/events");

      expect(service.channelServices, hasLength(1));
    });

    test("holds the service of the application, and no handler of its own", () async {
      final service = aService();
      final manager = await aServer(service: service);

      expect(manager.apiServices, [service]);
      expect(
        await manager.getGlobalHandlers(
          config: manager.serverConfig,
          httpLoggingManager: logging,
          apiServices: manager.apiServices,
        ),
        isEmpty,
      );
    });
  });

  group("AbsWebsocketApiService", () {
    test("opens one channel per client which connects", () async {
      final service = aService();
      await aServer(service: service);

      await aClient();
      await aClient();

      expect(service.channelServices, hasLength(2));
      expect(service.opened.map((channel) => channel.clientUuid).toSet(), hasLength(2));
    });

    test("reads the messages a client sends", () async {
      final service = aService();
      await aServer(service: service);
      final client = await aClient();

      final channel = service.opened.single;
      final received = expectLater(channel.receivedStream, emits("a message"));
      client.sink.add("a message");

      await received;
      expect(channel.received, ["a message"]);
    });

    test("sends a message to every client which is connected", () async {
      final service = aService();
      await aServer(service: service);
      final first = await aClient();
      final second = await aClient();

      final firstRead = expectLater(first.stream, emits("a message"));
      final secondRead = expectLater(second.stream, emits("a message"));

      expect(await service.sendRawMessageToAll("a message"), isTrue);
      await firstRead;
      await secondRead;
    });

    test("forgets the channel of a client which went away", () async {
      final service = aService();
      await aServer(service: service);
      final client = await aClient();

      await client.sink.close();
      await pumpEventQueue();

      expect(service.channelServices, isEmpty);
    });

    test("agrees with a client on a sub protocol both know", () async {
      final service = aService(
        websocketConfig: const WebsocketServerConfig(protocols: ["a.protocol"]),
      );
      await aServer(service: service);

      final client = await aClient(protocols: ["a.protocol"]);

      expect(client.protocol, "a.protocol");
      expect(service.opened.single.subProtocol, "a.protocol");
    });

    test("closes the channels of its clients once it is closed", () async {
      final service = aService();
      final manager = await aServer(service: service);
      await aClient();
      final channel = service.opened.single;

      await manager.disposeLifeCycle();

      expect(channel.isClosed, isTrue);
      expect(service.channelServices, isEmpty);
    });
  });

  group("AbsWebsocketChannelService", () {
    test("writes in the logs of the server that a client is listening", () async {
      await aServer(service: aService());

      await aClient();

      expect(
        logging.messages.any((message) => message.contains("start listening")),
        isTrue,
      );
    });

    test("writes in the logs of the server that a client went away", () async {
      final service = aService();
      await aServer(service: service);
      final client = await aClient();

      await client.sink.close();
      await pumpEventQueue();

      expect(logging.messages.any((message) => message.contains("stop listening")), isTrue);
    });

    test("writes the messages which travel in the logs of the server", () async {
      final service = aService();
      await aServer(service: service);
      final client = await aClient();
      final channel = service.opened.single;

      final received = expectLater(channel.receivedStream, emits("a message"));
      client.sink.add("a message");
      await received;
      await channel.sendRawMessage("an answer");

      expect(logging.logs.map((log) => log.method), containsAll(["RECEIVED", "SENT"]));
    });

    test("refuses to send anything on a channel which is closed", () async {
      final service = aService();
      await aServer(service: service);
      await aClient();
      final channel = service.opened.single;

      await channel.disposeLifeCycle();

      expect(await channel.sendRawMessage("a message"), isFalse);
    });
  });

  group("MixinWsEventApiService", () {
    /// The service which speaks with events on the WebSocket of the server of the test.
    FakeEventApiService anEventService() => FakeEventApiService(
      httpLoggingManager: logging,
      config: const HttpServerConfig(serverName: "a server", hostname: _host, port: _anyPort),
    );

    test("reads the event a client sends, and hands over its data", () async {
      final service = anEventService();
      await aServer(service: service);
      final client = await aClient();

      final channel = service.opened.single;
      final received = expectLater(channel.receivedStream, emits(FakeEvents.hello));
      client.sink.add(jsonEncode({"event": FakeEvents.hello.stringValue, "data": "a name"}));

      await received;
      expect(channel.received[FakeEvents.hello], ["a name"]);
    });

    test("reads nothing from a message which names an event it knows nothing about", () async {
      final service = anEventService();
      await aServer(service: service);
      final client = await aClient();

      client.sink.add(jsonEncode({"event": "anEventWhichDoesNotExist", "data": "a name"}));
      await pumpEventQueue();

      expect(service.opened.single.received, isEmpty);
    });

    test("sends an event to every client which is connected", () async {
      final service = anEventService();
      await aServer(service: service);
      final first = await aClient();
      final second = await aClient();

      final expected = jsonEncode({
        "event": FakeEvents.goodbye.stringValue,
        "data": "see you",
      });
      final firstRead = expectLater(first.stream, emits(expected));
      final secondRead = expectLater(second.stream, emits(expected));

      expect(
        await service.sendMessageToAll(event: FakeEvents.goodbye, data: "see you"),
        isTrue,
      );
      await firstRead;
      await secondRead;
    });
  });
}
