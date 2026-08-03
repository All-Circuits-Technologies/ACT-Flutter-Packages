// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_websocket_client_manager/act_websocket_client_manager.dart';

/// The events an application under test listens for.
enum FakeEvents with MixinStringValueType {
  /// The event a test sends to the parser.
  aThing;

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  String? get stringValueOverride => null;
}

/// The WebSocket server the tests of the manager talk to.
///
/// It answers on the loopback, on a port the machine gives it, so several tests can run one server
/// each without agreeing on a port beforehand.
class FakeWsServer {
  /// The server which accepts the sockets.
  final HttpServer _server;

  /// The sockets which are open, in the order they were opened.
  final List<WebSocket> sockets = [];

  /// The messages the sockets received, in the order they were received.
  final List<dynamic> received = [];

  /// The messages the sockets receive, as they are received.
  final StreamController<dynamic> _receivedCtrl = StreamController<dynamic>.broadcast();

  /// The stream a test waits on to know that a message reached the server.
  Stream<dynamic> get receivedStream => _receivedCtrl.stream;

  /// The number of sockets the server accepted.
  int connectionCount = 0;

  /// Class constructor
  FakeWsServer._(this._server);

  /// The address a client reaches the server at.
  Uri get uri => Uri.parse("ws://${_server.address.host}:${_server.port}");

  /// Starts a server on the loopback.
  static Future<FakeWsServer> start() async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = FakeWsServer._(httpServer);

    unawaited(server._accept());

    return server;
  }

  /// Sends [message] to every socket which is open.
  void send(String message) {
    for (final socket in sockets) {
      socket.add(message);
    }
  }

  /// Closes the sockets which are open, the way a server which goes down does.
  Future<void> closeSockets() async {
    final open = List<WebSocket>.from(sockets);
    sockets.clear();

    await Future.wait(open.map((socket) => socket.close()));
  }

  /// Stops the server and closes what it holds.
  Future<void> stop() async {
    await closeSockets();
    await _receivedCtrl.close();
    await _server.close(force: true);
  }

  /// Accepts the sockets the clients open, for as long as the server runs.
  Future<void> _accept() async {
    await for (final request in _server) {
      final socket = await WebSocketTransformer.upgrade(request);
      connectionCount++;
      sockets.add(socket);
      socket.listen((message) {
        received.add(message);
        _receivedCtrl.add(message);
      }, onDone: () => sockets.remove(socket));
    }
  }
}

/// A parser of the messages the WebSocket receives, which records them.
class FakeWsParser extends AbsWithLifeCycle with MixinWsMsgParserService {
  /// The messages the parser was handed, in the order it was handed them.
  final List<dynamic> messages = [];

  /// The number of times the parser was initialized.
  int initCount = 0;

  /// The number of times the parser was disposed.
  int disposeCount = 0;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    initCount++;
  }

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @override
  // The message received can be a string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    await super.onRawMessageReceived(message);

    messages.add(message);
  }

  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;

    return super.disposeLifeCycle();
  }
}

/// A parser of the events an application under test listens for.
class FakeEventParser extends AbsWsEventMsgParser<FakeEvents> {
  /// The data the parser was handed for each event it was told about.
  final List<dynamic> data = [];

  /// Class constructor
  FakeEventParser({super.parentLogger, super.eventJsonKey, super.dataJsonKey})
    : super(eventsList: FakeEvents.values, logsCategory: "aParser");

  /// Listens for [event] and records the data which comes with it.
  void listenFor(FakeEvents event) => registerEventCallback(event, data.add);
}

/// The configuration of an application which talks to a WebSocket server.
class FakeWsConfig extends AbstractConfigManager with MixinWebsocketClientConfig {
  /// Class constructor
  FakeWsConfig() : super(logger: const SilentLogger());
}

/// The WebSocket manager of an application, which runs on the configuration the test decided.
class FakeWsManager extends WebsocketClientManager {
  /// The configuration the manager runs on.
  final WsClientManagerConfig managerConfig;

  /// Class constructor
  FakeWsManager({required this.managerConfig})
    : super(configGetter: _noConfiguration, loggerCategory: "aWs");

  /// The manager reads no configuration manager: the test hands it its configuration.
  static MixinWebsocketClientConfig _noConfiguration() =>
      throw UnimplementedError("The manager of the tests reads no configuration manager");

  /// {@macro act_websocket_client_manager.WebsocketClientManager.getConfig}
  @override
  Future<WsClientManagerConfig> getConfig({required LogsHelper logsHelper}) async => managerConfig;
}
