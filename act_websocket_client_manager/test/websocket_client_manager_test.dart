// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_websocket_client_manager/act_websocket_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_websocket.dart';

/// The time the manager waits before it tries to connect again.
///
/// The tests wait for what the manager tells them rather than for this delay, but a manager which
/// waited the seconds a real one waits would hold the tests for as long.
const _reconnectDelay = Duration(milliseconds: 10);

void main() {
  late FakeWsServer server;

  setUp(() async {
    FakeGlobalManager.install();
    server = await FakeWsServer.start();
  });

  tearDown(() => server.stop());

  /// Builds the WebSocket manager of an application, and initializes it.
  Future<FakeWsManager> aManager({
    Uri? uri,
    bool startWsAtManagerInit = true,
    bool autoReconnectEnabled = false,
    List<MixinWsMsgParserService> msgParsers = const [],
    bool logReceivedMsg = false,
  }) async {
    final manager = FakeWsManager(
      managerConfig: WsClientManagerConfig(
        uri: uri ?? server.uri,
        autoReconnectEnabled: autoReconnectEnabled,
        autoReconnectInitDuration: _reconnectDelay,
        autoReconnectMaxDuration: _reconnectDelay,
        startWsAtManagerInit: startWsAtManagerInit,
        msgParsers: msgParsers,
        protocols: const [],
        logReceivedMsg: logReceivedMsg,
      ),
    );
    await manager.initLifeCycle();
    // The manager is closed before it is disposed, the way an application closes it: a socket
    // which is still open would tell a manager which no longer listens that it went down.
    addTearDown(() async {
      await manager.close();
      await manager.disposeLifeCycle();
    });

    return manager;
  }

  /// Builds a manager which is connected to the server.
  Future<FakeWsManager> aConnectedManager({
    bool autoReconnectEnabled = false,
    List<MixinWsMsgParserService> msgParsers = const [],
  }) async {
    final manager = await aManager(
      startWsAtManagerInit: false,
      autoReconnectEnabled: autoReconnectEnabled,
      msgParsers: msgParsers,
    );
    await manager.tryToConnect();

    return manager;
  }

  group("WebsocketClientDerivedBuilder", () {
    test("depends on the logger manager", () {
      expect(WebsocketClientDerivedBuilder<FakeWsConfig>().dependsOn(), [LoggerManager]);
    });
  });

  group("WebsocketClientManager.initLifeCycle", () {
    test("connects to the server when the application asks it to", () async {
      final manager = await aManager();

      await expectLater(
        manager.connectionStatusStream,
        emitsThrough(WsConnectionStatus.connected),
      );
      expect(server.connectionCount, 1);
    });

    test("waits for the application to ask when it was told to", () async {
      final manager = await aManager(startWsAtManagerInit: false);

      expect(manager.connectionStatus, WsConnectionStatus.disconnected);
      expect(server.connectionCount, 0);
    });

    test("initializes every parser of the application", () async {
      final parser = FakeWsParser();

      await aManager(startWsAtManagerInit: false, msgParsers: [parser]);

      expect(parser.initCount, 1);
    });
  });

  group("WebsocketClientManager.tryToConnect", () {
    test("says it connected to the server", () async {
      final manager = await aManager(startWsAtManagerInit: false);

      expect(await manager.tryToConnect(), isTrue);
      expect(manager.connectionStatus, WsConnectionStatus.connected);
    });

    test("tells the application it is connecting and then connected", () async {
      final manager = await aManager(startWsAtManagerInit: false);
      final statuses = <WsConnectionStatus>[];
      final subscription = manager.connectionStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      await manager.tryToConnect();
      await pumpEventQueue();

      expect(statuses, [WsConnectionStatus.connecting, WsConnectionStatus.connected]);
    });

    test("opens no second socket when it is already connected", () async {
      final manager = await aConnectedManager();

      expect(await manager.tryToConnect(), isTrue);
      expect(server.connectionCount, 1);
    });

    test("says it did not connect when nothing answers", () async {
      final manager = await aManager(
        startWsAtManagerInit: false,
        uri: Uri.parse("ws://127.0.0.1:1"),
      );

      expect(await manager.tryToConnect(), isFalse);
      expect(manager.connectionStatus, WsConnectionStatus.disconnected);
    });
  });

  group("WebsocketClientManager.sendMessage", () {
    test("sends the message to the server", () async {
      final manager = await aConnectedManager();
      final sent = expectLater(server.receivedStream, emits("a message"));

      expect(await manager.sendMessage("a message"), isTrue);

      await sent;
    });

    test("sends nothing while it is not connected", () async {
      final manager = await aManager(startWsAtManagerInit: false);

      expect(await manager.sendMessage("a message"), isFalse);
      expect(server.received, isEmpty);
    });
  });

  group("WebsocketClientManager.receivedMsgsStream", () {
    test("carries the messages the server sent", () async {
      final manager = await aConnectedManager();
      final received = expectLater(manager.receivedMsgsStream, emits("a message"));

      server.send("a message");

      await received;
    });

    test("hands every message to the parsers of the application", () async {
      final parser = FakeWsParser();
      final manager = await aConnectedManager(msgParsers: [parser]);
      final received = expectLater(manager.receivedMsgsStream, emits("a message"));

      server.send("a message");
      await received;

      expect(parser.messages, ["a message"]);
    });
  });

  group("WebsocketClientManager.close", () {
    test("disconnects from the server", () async {
      final manager = await aConnectedManager();

      await manager.close();

      expect(manager.connectionStatus, WsConnectionStatus.disconnected);
    });

    test("stops sending", () async {
      final manager = await aConnectedManager();

      await manager.close();

      expect(await manager.sendMessage("a message"), isFalse);
    });

    test("connects again when the application asks for it", () async {
      final manager = await aConnectedManager();
      await manager.close();

      expect(await manager.tryToConnect(), isTrue);
      expect(server.connectionCount, 2);
    });
  });

  group("WebsocketClientManager", () {
    test("goes back to disconnected when the server closes the socket", () async {
      final manager = await aConnectedManager();
      final disconnected = expectLater(
        manager.connectionStatusStream,
        emitsThrough(WsConnectionStatus.disconnected),
      );

      await server.closeSockets();

      await disconnected;
    });

    test("connects again by itself when the application asked it to", () async {
      final manager = await aConnectedManager(autoReconnectEnabled: true);
      final connectedAgain = expectLater(
        manager.connectionStatusStream,
        emitsThrough(WsConnectionStatus.disconnected),
      ).then(
        (_) => expectLater(manager.connectionStatusStream, emitsThrough(WsConnectionStatus.connected)),
      );

      await server.closeSockets();
      await connectedAgain;

      expect(server.connectionCount, 2);
    });

    test("stays disconnected when the application did not ask it to reconnect", () async {
      final manager = await aConnectedManager();
      final disconnected = expectLater(
        manager.connectionStatusStream,
        emitsThrough(WsConnectionStatus.disconnected),
      );

      await server.closeSockets();
      await disconnected;
      await pumpEventQueue();

      expect(server.connectionCount, 1);
    });

    test("stops connecting again once the application closed it", () async {
      final manager = await aConnectedManager(autoReconnectEnabled: true);
      final disconnected = expectLater(
        manager.connectionStatusStream,
        emitsThrough(WsConnectionStatus.disconnected),
      );

      await manager.close();
      await disconnected;
      await pumpEventQueue();

      expect(server.connectionCount, 1);
    });
  });

  group("WebsocketClientManager.disposeLifeCycle", () {
    test("stops telling the application about the messages and the connection", () async {
      final manager = await aManager(startWsAtManagerInit: false);
      final messagesDone = expectLater(manager.receivedMsgsStream, emitsDone);
      final statusDone = expectLater(manager.connectionStatusStream, emitsDone);

      await manager.disposeLifeCycle();

      await messagesDone;
      await statusDone;
    });

    test("disposes every parser of the application", () async {
      final parser = FakeWsParser();
      final manager = await aManager(startWsAtManagerInit: false, msgParsers: [parser]);

      await manager.disposeLifeCycle();

      expect(parser.disposeCount, 1);
    });
  });
}
