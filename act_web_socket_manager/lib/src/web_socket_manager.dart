// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_web_socket_manager/src/mixins/mixin_web_socket_config.dart';
import 'package:act_web_socket_manager/src/models/ws_manager_config.dart';
import 'package:act_web_socket_manager/src/types/ws_connection_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Builder to use with derived class in order to create a WebSocketManager with the right type.
///
/// This is useful if you want to create another [WebSocketManager] to contact another WebSocket
/// server.
abstract class AbstractWebSocketDerivedBuilder<T extends WebSocketManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor with the class construction
  const AbstractWebSocketDerivedBuilder({required ClassFactory<T> factory}) : super(factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Builder for creating the WebSocketManager
class WebSocketDerivedBuilder<C extends MixinWebSocketConfig>
    extends AbstractWebSocketDerivedBuilder<WebSocketManager> {
  /// Class constructor
  WebSocketDerivedBuilder()
    : super(factory: () => WebSocketManager(configGetter: globalGetIt().get<C>));
}

/// This is the web socket manager
///
/// If you want to create multiple managers, use [AbstractWebSocketDerivedBuilder].
class WebSocketManager extends AbsWithLifeCycle {
  /// This is the default value of the start web socket at manager init
  static const _startWsAtManagerInitDefaultValue = true;

  /// This is the default logger category
  static const defaultLoggerCategory = "ws";

  /// This is the manager logger category
  final String loggerCategory;

  /// This is the logs helper of the manager
  late final LogsHelper logsHelper;

  /// This is the getter of the config manager
  final MixinWebSocketConfig Function() _configGetter;

  /// This is the mutex linked to the connection
  final Mutex _connectionMutex;

  /// This is the received message stream controller
  final StreamController<dynamic> _receivedMsgCtrl;

  /// This is the connection status stream controller
  final StreamController<WsConnectionStatus> _connectionStatusCtrl;

  /// This is the config of the manager
  late final WsManagerConfig _managerConfig;

  /// This is the timer used to auto reconnect to the WebSocket
  ProgressingRestartableTimer? _autoRecoTimer;

  /// This is the subscription to the channel stream
  StreamSubscription? _webSocketSubscription;

  /// This is the connection status
  WsConnectionStatus _connectionStatus;

  /// Getter of the connection status
  WsConnectionStatus get connectionStatus => _connectionStatus;

  /// This is the stream of received messages
  Stream<dynamic> get receivedMsgsStream => _receivedMsgCtrl.stream;

  /// This is the stream of the connection status
  Stream<WsConnectionStatus> get connectionStatusStream => _connectionStatusCtrl.stream;

  /// This is the web socket channel
  WebSocketChannel? _channel;

  /// Class constructor
  WebSocketManager({
    required MixinWebSocketConfig Function() configGetter,
    this.loggerCategory = defaultLoggerCategory,
  }) : _configGetter = configGetter,
       _connectionStatus = WsConnectionStatus.disconnected,
       _connectionMutex = Mutex(),
       _connectionStatusCtrl = StreamController.broadcast(),
       _receivedMsgCtrl = StreamController.broadcast();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: loggerCategory);
    _managerConfig = await getConfig(logsHelper: logsHelper);

    await Future.wait(_managerConfig.msgParsers.map((parser) => parser.initLifeCycle()));

    if (_managerConfig.startWsAtManagerInit) {
      // We don't wait for the web socket connection success
      unawaited(tryToConnect());
    }
  }

  /// {@macro act_web_socket_manager.WebSocketManager.tryToConnect}
  ///
  /// If [enableAutoReconnect] is different of null, it will enable (or not) the auto reconnect
  Future<bool> tryToConnect({bool? enableAutoReconnect}) => _connectionMutex.protect(() async {
    await _manageAutoReconnect(enableAutoReconnect: enableAutoReconnect);
    return _tryToConnectProcess();
  });

  /// {@template act_web_socket_manager.WebSocketManager.sendMessage}
  /// Send message through the web socket.
  ///
  /// Return false, if the web socket isn't connected
  /// {@endtemplate}
  // The message sent can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendMessage(dynamic message) => _connectionMutex.protect(() async {
    if (_connectionStatus != WsConnectionStatus.connected || _channel == null) {
      logsHelper.w("The web socket isn't connected, we can't send the message");
      return false;
    }

    _channel!.sink.add(message);
    return true;
  });

  /// {@template act_web_socket_manager.WebSocketManager.close}
  /// This closes the current web socket and disable all the auto reconnection
  /// {@endtemplate}
  Future<void> close() => _connectionMutex.protect(() async {
    _stopAutoReconnection();
    await _channel?.sink.close(status.goingAway);
    await _manageWebSocketDisconnect();
  });

  /// {@template act_web_socket_manager.WebSocketManager.getConfig}
  /// Get the manager config, use value by default
  /// {@endtemplate}
  @protected
  Future<WsManagerConfig> getConfig({required LogsHelper logsHelper}) async => WsManagerConfig(
    uri: _configGetter().webSocketUrl.load(),
    autoReconnectEnabled: _configGetter().webSocketAutoRecoEnabled.load(),
    autoReconnectInitDuration: _configGetter().webSocketAutoRecoInitDurationInMs.load(),
    autoReconnectMaxDuration: _configGetter().webSocketAutoRecoMaxDurationInMs.load(),
    startWsAtManagerInit: _startWsAtManagerInitDefaultValue,
    msgParsers: const [],
    protocols: const [],
    logReceivedMsg: _configGetter().webSocketLogReceivedMsg.load(),
  );

  /// This is callback called when the auto reconnect is triggered
  Future<bool> _autoReconnectCallback() => _connectionMutex.protect(() async {
    await _tryToConnectProcess();

    // Because the timer doesn't auto restart the value returned by this method doesn't matter.
    // But we return false by precaution
    return false;
  });

  /// {@template act_web_socket_manager.WebSocketManager.tryToConnect}
  /// Try to connect to the WebSocket server
  ///
  /// If we are already connected, the method does nothing
  /// {@endtemplate}
  Future<bool> _tryToConnectProcess() async {
    if (_connectionStatus != WsConnectionStatus.disconnected) {
      // Nothing more to do
      // We shouldn't be in the connecting state here because we wait the success, or not, of the
      // connection in this method. Therefore, the mutex will block the call until we reach the
      // disconnected or connected state
      return true;
    }

    _setConnectionStatus(WsConnectionStatus.connecting);

    var anErrorOccurred = false;
    Future<void> connectingErrorCallback(Object error, StackTrace stackTrace) async {
      if (_connectionStatus == WsConnectionStatus.connecting) {
        anErrorOccurred = true;
      }

      await _onWsError(error, stackTrace);
    }

    try {
      final protocols = _managerConfig.protocols;
      _channel = WebSocketChannel.connect(
        _managerConfig.uri,
        protocols: protocols.isNotEmpty ? protocols : null,
      );
      _webSocketSubscription = _channel!.stream.listen(
        _onMsgCallback,
        onError: connectingErrorCallback,
        onDone: _onWsDone,
      );
      await _channel!.ready;
    } catch (error, stack) {
      logsHelper.e("An error occurred when trying to connect to the web socket: $error");
      await connectingErrorCallback(error, stack);
    }

    if (anErrorOccurred) {
      await _manageWebSocketDisconnect();
      return false;
    }

    _setConnectionStatus(WsConnectionStatus.connected);

    return true;
  }

  /// Called when a message is received on the web socket
  Future<void> _onMsgCallback(message) async {
    if (_managerConfig.logReceivedMsg) {
      logsHelper.t(message);
    }

    await Future.wait(_managerConfig.msgParsers.map((parser) => parser.onMessageReceived(message)));
    _receivedMsgCtrl.add(message);
  }

  /// Called when an error is received from the Web socket
  Future<void> _onWsError(Object error, StackTrace stackTrace) async {
    if (_connectionStatus == WsConnectionStatus.disconnected) {
      // Nothing to do
      return;
    }

    logsHelper.w(
      "An error occurred in the web socket stream message: $error, stack trace: $stackTrace",
    );

    if (_connectionStatus == WsConnectionStatus.connecting) {
      // We are connecting to the web socket, this is directly managed by the [tryToConnect] method
      return;
    }

    await _manageWebSocketDisconnect();
  }

  /// Called when the Web Socket is closed
  Future<void> _onWsDone() async {
    if (_connectionStatus == WsConnectionStatus.disconnected ||
        _connectionStatus == WsConnectionStatus.connecting) {
      // Nothing to do, something else has managed or is managing the case
      return;
    }

    await _manageWebSocketDisconnect();
  }

  /// Set the connection status and emit an event if it has been updated
  void _setConnectionStatus(WsConnectionStatus status) {
    if (status != _connectionStatus) {
      _connectionStatus = status;
      _connectionStatusCtrl.add(status);
    }
  }

  /// Manage the Web Socket disconnection
  ///
  /// This is used to free all the elements which needs to be
  Future<void> _manageWebSocketDisconnect() async {
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    _channel = null;
    _setConnectionStatus(WsConnectionStatus.disconnected);

    // If the auto reconnection is enabled, we restart the process
    _autoRecoTimer?.restart();
  }

  /// Manage the enabling of the web socket auto reconnection
  ///
  /// If [enableAutoReconnect] is different of null, it will enable (or not) the auto reconnect.
  /// If [enableAutoReconnect] is equal to null, it will use the value returned by
  /// [_managerConfig] autoReconnectEnabled property.
  ///
  /// The call to this method will reset the [_autoRecoTimer].
  Future<void> _manageAutoReconnect({bool? enableAutoReconnect}) async {
    final isAutoRecoEnabled = enableAutoReconnect ?? _managerConfig.autoReconnectEnabled;
    if (isAutoRecoEnabled && _autoRecoTimer != null) {
      // Nothing more to do, except the reset of the timer
      _autoRecoTimer!.reset();
    } else if (!isAutoRecoEnabled && _autoRecoTimer == null) {
      // Nothing to do
    } else if (!isAutoRecoEnabled) {
      _stopAutoReconnection();
    } else {
      _autoRecoTimer = ProgressingRestartableTimer.logFactor(
        _managerConfig.autoReconnectInitDuration,
        _autoReconnectCallback,
        waitNextRestartToStart: true,
        maxDuration: _managerConfig.autoReconnectMaxDuration,
      );
    }
  }

  /// This stop the auto reconnection
  void _stopAutoReconnection() {
    _autoRecoTimer?.reset();
    _autoRecoTimer = null;
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_managerConfig.msgParsers.map((parser) => parser.disposeLifeCycle()));
    await _receivedMsgCtrl.close();
    await _connectionStatusCtrl.close();

    await super.disposeLifeCycle();
  }
}
