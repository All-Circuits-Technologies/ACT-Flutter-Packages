// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_websocket_server_manager/act_websocket_server_manager.dart';

/// The events an application under test speaks with.
enum FakeEvents with MixinStringValueType {
  /// An event a client sends to the server.
  hello,

  /// An event the server sends to its clients.
  goodbye;

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  String? get stringValueOverride => null;
}

/// The logging manager of a server, which keeps the logs the test reads.
class FakeHttpLogging extends HttpLoggingManager {
  /// The logs the server wrote, in the order it wrote them.
  final List<HttpLog> logs = [];

  /// The messages of the logs the server wrote.
  List<String> get messages => logs.map((log) => log.message).toList();

  /// {@macro act_http_logging_manager.HttpLoggingManager.addLog}
  @override
  void addLog(HttpLog log) {
    logs.add(log);
    super.addLog(log);
  }
}

/// The channel of one client of the server of an application under test.
class FakeChannelService extends AbsWebsocketChannelService {
  /// The messages the client sent, in the order they were received.
  final List<dynamic> received = [];

  /// The messages the client sent, as they are received.
  final StreamController<dynamic> _receivedCtrl = StreamController<dynamic>.broadcast();

  /// The sub protocol the client and the server agreed on.
  final String? subProtocol;

  /// Class constructor
  FakeChannelService({
    required super.webSocket,
    required super.httpLoggingManager,
    required super.onClose,
    this.subProtocol,
  });

  /// The stream a test waits on to know that a message reached the server.
  Stream<dynamic> get receivedStream => _receivedCtrl.stream;

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @override
  // The message received can be a string or bytes
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    await super.onRawMessageReceived(message);

    received.add(message);
    if (!_receivedCtrl.isClosed) {
      _receivedCtrl.add(message);
    }
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _receivedCtrl.close();

    return super.disposeLifeCycle();
  }
}

/// The channel of one client of a server which speaks with events.
class FakeEventChannelService extends AbsWsEventChannelService<FakeEvents> {
  /// The data of the events the client sent, one entry per event.
  final Map<FakeEvents, List<dynamic>> received = {};

  /// The data of the events the client sent, as they are received.
  final StreamController<FakeEvents> _receivedCtrl = StreamController<FakeEvents>.broadcast();

  /// Class constructor
  FakeEventChannelService({
    required super.webSocket,
    required super.httpLoggingManager,
    required super.onClose,
  }) : super(eventsList: FakeEvents.values) {
    registerEventCallback(FakeEvents.hello, (data) => _onEvent(FakeEvents.hello, data));
  }

  /// The stream a test waits on to know that an event reached the server.
  Stream<FakeEvents> get receivedStream => _receivedCtrl.stream;

  /// Records the data of [event], the way a service of an application would read it.
  // The data of an event can be anything the two sides agreed on
  // ignore: avoid_annotating_with_dynamic
  void _onEvent(FakeEvents event, dynamic data) {
    received.putIfAbsent(event, () => []).add(data);
    if (!_receivedCtrl.isClosed) {
      _receivedCtrl.add(event);
    }
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _receivedCtrl.close();

    return super.disposeLifeCycle();
  }
}

/// The WebSocket service of an application under test.
class FakeWsApiService extends AbsWebsocketApiService<FakeChannelService> {
  /// The configuration of the WebSocket server, when the application decides one.
  final WebsocketServerConfig? websocketConfig;

  /// The channels the service opened, in the order it opened them.
  final List<FakeChannelService> opened = [];

  /// Class constructor
  FakeWsApiService({
    required super.httpLoggingManager,
    required super.config,
    super.serviceRelativePath,
    this.websocketConfig,
  });

  /// {@macro act_websocket_server_manager.AbsWebsocketService.getWsConfig}
  @override
  Future<WebsocketServerConfig> getWsConfig() async =>
      websocketConfig ?? super.getWsConfig();

  /// {@macro act_websocket_server_manager.AbsWebsocketService.createChannelService}
  @override
  Future<FakeChannelService> createChannelService({
    required HttpLoggingManager httpLoggingManager,
    required WebSocketChannel channel,
    required String? subProtocol,
    required void Function(String clientUuid) onClose,
  }) async {
    final service = FakeChannelService(
      webSocket: channel,
      httpLoggingManager: httpLoggingManager,
      onClose: onClose,
      subProtocol: subProtocol,
    );
    opened.add(service);

    return service;
  }
}

/// The WebSocket service of an application which speaks with events.
class FakeEventApiService extends AbsWebsocketApiService<FakeEventChannelService>
    with MixinWsEventApiService<FakeEvents, FakeEventChannelService> {
  /// The channels the service opened, in the order it opened them.
  final List<FakeEventChannelService> opened = [];

  /// Class constructor
  FakeEventApiService({
    required super.httpLoggingManager,
    required super.config,
    super.serviceRelativePath,
  });

  /// {@macro act_websocket_server_manager.AbsWebsocketService.createChannelService}
  @override
  Future<FakeEventChannelService> createChannelService({
    required HttpLoggingManager httpLoggingManager,
    required WebSocketChannel channel,
    required String? subProtocol,
    required void Function(String clientUuid) onClose,
  }) async {
    final service = FakeEventChannelService(
      webSocket: channel,
      httpLoggingManager: httpLoggingManager,
      onClose: onClose,
    );
    opened.add(service);

    return service;
  }
}

/// The configuration of an application which runs a WebSocket server.
class FakeWsServerConfig extends AbstractConfigManager with MixinWebsocketServerConfig {
  /// Class constructor
  FakeWsServerConfig() : super(logger: const SilentLogger());
}

/// The WebSocket server manager of an application under test.
class FakeWsServerManager extends AbsWebsocketServerManager {
  /// The configuration of the server.
  final HttpServerConfig serverConfig;

  /// The logging manager of the server.
  final HttpLoggingManager logging;

  /// The service which answers on the route of the WebSocket.
  final AbsWebsocketApiService service;

  /// Whether the server has already been closed.
  bool disposed = false;

  /// Class constructor
  FakeWsServerManager({
    required this.serverConfig,
    required this.logging,
    required this.service,
  });

  /// {@macro act_http_server_manager.HttpServerManager.getLoggingManager}
  @override
  Future<HttpLoggingManager> getLoggingManager() async => logging;

  /// {@macro act_http_server_manager.HttpServerManager.getServerConfig}
  @override
  Future<HttpServerConfig> getServerConfig({
    required HttpLoggingManager httpLoggingManager,
  }) async => serverConfig;

  /// {@macro act_websocket_server_manager.AbsWebsocketServerManager.getWebsocketService}
  @override
  Future<AbsWebsocketApiService> getWebsocketService({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  }) async => service;

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    if (disposed) {
      return;
    }

    disposed = true;

    return super.disposeLifeCycle();
  }
}

/// The builder of the WebSocket server manager of an application under test.
class FakeWsServerBuilder extends AbsWebsocketServerBuilder<FakeWsServerManager> {
  /// Class constructor
  const FakeWsServerBuilder(super.factory);
}

/// The WebSocket server manager of an application which reads its configuration from its
/// configuration manager.
class FakeConfiguredWsServerManager extends AbsWebsocketServerManager
    with MixinFromConfigWsServerManager {
  /// The configuration manager of the application.
  final FakeWsServerConfig configManager;

  /// Class constructor
  FakeConfiguredWsServerManager({required this.configManager});

  /// {@macro act_websocket_server_manager.MixinFromConfigWsServerManager.configGetter}
  @override
  MixinWebsocketServerConfig Function() get configGetter => () => configManager;

  /// The configuration of the server, as the mixin reads it from the configuration manager.
  Future<HttpServerConfig> readServerConfig(HttpLoggingManager logging) =>
      getServerConfig(httpLoggingManager: logging);

  /// {@macro act_websocket_server_manager.AbsWebsocketServerManager.getWebsocketService}
  @override
  Future<AbsWebsocketApiService> getWebsocketService({
    required HttpServerConfig config,
    required HttpLoggingManager httpLoggingManager,
  }) async => throw UnimplementedError("This manager is only read for its configuration");
}
