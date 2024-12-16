// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_request_manager/act_server_request_manager.dart';
import 'package:act_thingsboard/src/data/abstract_constants_manager.dart';
import 'package:act_thingsboard/src/device_manager.dart';
import 'package:act_thingsboard/src/model/device.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';
import 'package:act_thingsboard/src/model/web_socket_receive_message.dart';
import 'package:act_thingsboard/src/model/web_socket_send_message.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:act_thingsboard/src/token_manager.dart';
import 'package:act_thingsboard/src/ws/ws_connection_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/io.dart';

/// Builder for creating the WebSocketManager
class WebSocketBuilder extends ManagerBuilder<WebSocketManager> {
  /// Class constructor with the class construction
  WebSocketBuilder() : super(() => WebSocketManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        LoggerManager,
        TokenManager,
        LifeCycleManager,
      ];
}

/// Web socket client service
///
/// We don't allow to refuse to use the "autoConnect" function
class WebSocketManager extends AbstractManager {
  WsConnectionStatus _status;
  IOWebSocketChannel _channel;
  StreamController<WsConnectionStatus> _wsStatusStreamController;
  StreamSubscription _channelSub;
  StreamSubscription<ServerComState> _requestComStateSub;
  StreamSubscription<AppLifecycleState> _lifeCycleSub;

  bool _firstMessage;
  LockUtility _connectionLock;
  ProgressingRestartableTimer _autoReconnectTimer;
  int _connectionTried = 0;

  /// The [_currentUniqueId] is unique for the current connection
  int _currentUniqueId;
  List<WebSocketSendMessage> _messagesSent;

  /// [WebSocketManager] constructor
  WebSocketManager() : super() {
    _status = WsConnectionStatus.disconnected;
    _messagesSent = [];
  }

  /// Init the manager
  @override
  Future<void> initManager() async {
    _connectionLock = LockUtility();

    _wsStatusStreamController =
        StreamController<WsConnectionStatus>.broadcast();

    _autoReconnectTimer = ProgressingRestartableTimer.expFactor(
      AbstractConstantsManager.webSocketAutoReconnectMinInterval,
      _autoReconnectCallback,
      maxDuration: AbstractConstantsManager.webSocketAutoReconnectMaxInterval,
      waitNextResetToStart: true,
    );

    GlobalGetIt()
        .get<DeviceManager>()
        .cacheDevicesStream
        .listen(_onDeviceListUpdate);

    _requestComStateSub = GlobalGetIt()
        .get<ServerRequestManager>()
        .requestStateStream
        .listen(_onNewRequestComState);

    _lifeCycleSub = GlobalGetIt()
        .get<LifeCycleManager>()
        .lifeCycleStream
        .listen(_onAppLifeCycleUpdate);
  }

  /// Dispose the class
  @override
  Future<void> dispose() async {
    return Future.wait([
      _disconnectImpl(),
      _requestComStateSub.cancel(),
      _lifeCycleSub.cancel(),
    ]);
  }

  /// Get the web socket connection status stream
  Stream<WsConnectionStatus> get wsStatusStream =>
      _wsStatusStreamController.stream;

  /// Test if the web socket is currently in the auto reconnect mode on
  bool get isAutoReconnectOn =>
      (_status == WsConnectionStatus.connected) ||
      _autoReconnectTimer.isActive ||
      _connectionLock.isLocked;

  /// Get the current status of the web socket connection
  WsConnectionStatus get status => _status;

  /// Return an unique id for web socket message
  ///
  /// This will returns the current unique id and then increment it
  int generateUniqueId() => _currentUniqueId++;

  /// Connect to the web socket, if the web socket is already connected does
  /// nothing
  Future<bool> connect() async {
    LockEntity lockEntity = await _connectionLock.waitAndLock();

    if (_channel != null && _channel.closeCode == null) {
      // The web socket is currently connected, no need to reconnect
      lockEntity.freeLock();
      return true;
    }

    _currentUniqueId = 0;
    _messagesSent.clear();
    _connectionTried++;
    _firstMessage = true;

    if (_channel != null && _channel.closeCode != null) {
      await _disconnectImpl();
    }

    TokenManager tokenManager = GlobalGetIt().get<TokenManager>();

    String token = await tokenManager.getToken();

    RequestResult authResult = await _tryToConnectToWebSocket(token);

    if (authResult != RequestResult.Ok) {
      await _manageError(authResult);
      lockEntity.freeLock();
      return false;
    }

    Tuple2<RequestResult, List<Device>> result =
        await GlobalGetIt().get<DeviceManager>().getDevices();

    if (result.item1 != RequestResult.Ok) {
      await _manageError(result.item1);
      lockEntity.freeLock();
      return false;
    }

    _channelSub = _channel.stream.listen(
      _onNewMessage,
      onError: _onError,
      onDone: _onDone,
    );

    if (result.item2.isNotEmpty) {
      await _subscribeToUserDevices(result.item2);
    } else {
      // If there is no device to subscribe, we will never receive a message
      // from Web Socket; therefore we consider that it's working
      _manageFirstMessage();
    }

    lockEntity.freeLock();
    return true;
  }

  /// Try to connect to the web socket with the token given
  Future<RequestResult> _tryToConnectToWebSocket(String token) async {
    RequestResult authResult = RequestResult.Ok;

    AppLogger().d("[WS] Try to connect to web socket");

    if (token?.isEmpty ?? true) {
      Tuple2<RequestResult, String> tokenResult =
          await GlobalGetIt().get<TokenManager>().refreshToken();
      authResult = tokenResult.item1;
      token = tokenResult.item2;
    }

    if (authResult != RequestResult.Ok) {
      return authResult;
    }

    Uri wssUri = buildWebSocketUri(token);

    IOWebSocketChannel tmpChannel;

    try {
      tmpChannel = IOWebSocketChannel.connect(
        wssUri,
        pingInterval: AbstractConstantsManager.webSocketPingIntervalDuration,
      );
    } catch (error) {
      // Analyze the error returned
      authResult = ServerHelper.parseRequestError(error);
    }

    if (authResult == RequestResult.Ok) {
      _channel = tmpChannel;
    }

    return authResult;
  }

  /// The disconnect method has only to be used outside the [WebSocketManager]
  /// class.
  ///
  /// It allows to stop the current connection and also stop the auto
  /// reconnecting behavior.
  Future<void> disconnect() async {
    LockEntity lockEntity = await _connectionLock.waitAndLock();

    if (_autoReconnectTimer.isActive) {
      // Cancel if an auto reconnect is alive
      _autoReconnectTimer.cancel();
    }

    await _disconnectImpl();

    lockEntity.freeLock();
    return;
  }

  /// Disconnect to the web socket
  Future<void> _disconnectImpl() async {
    if (_channel == null) {
      // No need to disconnect
      return;
    }

    WsConnectionStatus beforeStatus = _status;

    _setConnectionStatus(WsConnectionStatus.disconnected);

    var oldChannel = _channel;
    var oldChannelSub = _channelSub;

    _channel = null;
    _channelSub = null;

    var futures = <Future>[];

    if (oldChannelSub != null) {
      futures.add(oldChannelSub.cancel());
    }

    if (beforeStatus == WsConnectionStatus.connected) {
      // The close method of sink doesn't return with await when the sink hasn't
      // be built. Therefore we only close the sink if we know that the web
      // socket connection has been established
      futures.add(oldChannel.sink.close());
    }

    return Future.wait(futures);
  }

  /// Called when a new message is received from the server
  void _onNewMessage(var message) {
    _manageFirstMessage();

    AppLogger().d("[WS] Message received: $message");

    Map<String, dynamic> rawJson;

    try {
      rawJson = jsonDecode(message as String) as Map<String, dynamic>;
    } catch (error) {
      AppLogger().w("An error occurred when trying to parse the web "
          "socket message");
    }

    if (rawJson is! Map<String, dynamic>) {
      AppLogger().w("Nothing received from server");
      return;
    }

    WebSocketReceiveMessage wsMsg = WebSocketReceiveMessage.fromJson(rawJson);

    Tuple2<TypeOfSub, EntityId> result = findDeviceLinked(wsMsg);

    if (result == null) {
      // Do nothing with the message: the device is not known and/or it's not
      // an attribute msg
      return;
    }

    DeviceManager deviceManager = GlobalGetIt().get<DeviceManager>();

    switch (result.item1) {
      case TypeOfSub.attributes:
        deviceManager.updateAttributesFromServer(result.item2, wsMsg);
        break;

      case TypeOfSub.history:
      case TypeOfSub.timeseries:
        // This kind of subscription isn't managed for now
        break;
    }
  }

  void _manageFirstMessage() {
    if (_firstMessage) {
      // This is compulsory because there is no other way to know if the web
      // socket has been successfully connected to server
      // We can do that, because we send a message just after we have been
      // connected to the server
      _firstMessage = false;
      _connectionTried = 0;

      // Reset the timer
      _autoReconnectTimer = ProgressingRestartableTimer.expFactor(
        AbstractConstantsManager.webSocketAutoReconnectMinInterval,
        _autoReconnectCallback,
        maxDuration: AbstractConstantsManager.webSocketAutoReconnectMaxInterval,
        waitNextResetToStart: true,
      );

      if (_channel != null) {
        _setConnectionStatus(WsConnectionStatus.connected);
      }
    }
  }

  /// Called when an error occurred with the current web socket
  ///
  /// This method is also called when an error occurred in the connection
  /// process
  void _onError(var error) {
    _manageError(error);
  }

  Future<void> _manageError(error) async {
    RequestResult result = ServerHelper.parseRequestError(error);
    bool retryConnection = true;

    switch (result) {
      case RequestResult.Ok:
      case RequestResult.GenericError:
      case RequestResult.WrongAddress:
        // Useless to try to connect in loop, therefore we let as it
        break;
      case RequestResult.DisconnectFromNetwork:
        // We have been disconnected from network, we try to reconnect and don't
        // use _connectionTried
        _connectionTried = 0;
        break;
      case RequestResult.WrongCredentials:
        // We refresh token
        Tuple2<RequestResult, String> refreshResult =
            await GlobalGetIt().get<TokenManager>().refreshToken();
        if (refreshResult.item1 != RequestResult.Ok) {
          retryConnection = false;
          // No need to retry
        }
    }

    if (_connectionTried == ServerConstants.maxTryNumberBeforeError) {
      retryConnection = false;
      AppLogger().w("[WS] We raise the max try number, we won't retry "
          "to connect");
    }

    await _disconnectImpl();

    if (retryConnection) {
      _resetTimerIfNeeded();
    }
  }

  /// Called when the web socket is closed (it can have been closed by client or
  /// server)
  void _onDone() {
    AppLogger().i("[WS] web socket closed: ${_channel?.closeCode}");

    if (_status == WsConnectionStatus.connected) {
      RequestResult error = RequestResult.GenericError;

      if (_channel != null) {
        if (_channel.closeCode == WebSocketStatus.goingAway) {
          error = RequestResult.DisconnectFromNetwork;
        }
      }

      // That means that we expect to be still connected but a problem occurs
      _manageError(error);
    }

    _disconnectImpl();
  }

  /// Set the current connection status
  ///
  /// If the status has changed the new status is sent to the stream
  void _setConnectionStatus(WsConnectionStatus wsStatus) {
    if (wsStatus != _status) {
      _status = wsStatus;

      AppLogger().i("Web socket ${wsStatus.str}");

      _wsStatusStreamController.add(wsStatus);
    }
  }

  /// Called by the auto reconnect timer
  void _autoReconnectCallback() {
    connect();
  }

  /// Reset timer if it's not already active
  void _resetTimerIfNeeded() {
    if (!_autoReconnectTimer.isActive) {
      _autoReconnectTimer.reset();
    }
  }

  /// This method is called when the device list changes and if there is new
  /// devices, subscribe to them
  void _onDeviceListUpdate(List<Device> devices) {
    if (_status == WsConnectionStatus.disconnected) {
      // The web socket is disconnected can't subscribe for devices
      return;
    }

    List<Device> devicesToSub = [];

    for (Device device in devices) {
      bool found = false;
      for (WebSocketSendMessage wsMsg in _messagesSent) {
        // TODO For now we only test the attributes but in future we may want
        // TODO to also subscribe to timeseries
        if (wsMsg.isDeviceSubForAttr(device)) {
          found = true;
          break;
        }
      }

      if (!found) {
        devicesToSub.add(device);
      }
    }

    if (devicesToSub.isNotEmpty) {
      _subscribeToUserDevices(devicesToSub);
    }
  }

  /// This method allows to subscribe to specific devices
  Future<void> _subscribeToUserDevices(List<Device> devices) async {
    var wsMsg = WebSocketSendMessage(
      generateUniqueMsgId: generateUniqueId,
      attributesSubCmds: devices,
    );

    _messagesSent.add(wsMsg);

    _channel?.sink?.add(jsonEncode(wsMsg.toJson()));
  }

  Tuple2<TypeOfSub, EntityId> findDeviceLinked(WebSocketReceiveMessage wsMsg) {
    int subId = wsMsg.subscriptionId;

    for (WebSocketSendMessage sendMsg in _messagesSent) {
      Tuple2<TypeOfSub, EntityId> result = sendMsg.getDeviceId(subId);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  /// Called when a new request communication state is received
  ///
  /// If a request to server has succeeded, we don't wait the next tick, we
  /// try to reconnect right away
  void _onNewRequestComState(ServerComState serverState) {
    if (_status == WsConnectionStatus.disconnected &&
        _autoReconnectTimer.isActive &&
        serverState == ServerComState.Ok) {
      _autoReconnectTimer.cancel();
      _autoReconnectCallback();
    }
  }

  /// Called when the application life cycle changed
  ///
  /// This disconnect the WebSocket when we go to background and reconnect when
  /// we go to foreground
  void _onAppLifeCycleUpdate(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLogger().d("The mobile App is paused");
      disconnect();
    } else if (state == AppLifecycleState.resumed &&
        _status == WsConnectionStatus.disconnected &&
        !_connectionLock.isLocked) {
      AppLogger().d("The mobile App has come to live, and retry to connect");
      if (_autoReconnectTimer.isActive) {
        _autoReconnectTimer.cancel();
      }

      _autoReconnectCallback();
    }
  }

  /// Build the web socket uri with the [token] given
  static Uri buildWebSocketUri(String token) {
    var constManager = GlobalGetIt().get<AbstractConstantsManager>();

    return Uri(
        scheme: constManager.webSocketTlsScheme,
        host: constManager.fqdnHttp,
        port: constManager.portHttps,
        path: AbstractConstantsManager.webSocketRelativeUri,
        queryParameters: {
          AbstractConstantsManager.webSocketTokenParam: token,
        });
  }
}
