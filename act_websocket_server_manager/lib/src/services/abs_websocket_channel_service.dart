// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_websocket_core/act_websocket_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// This is the abstract class to manage a specific WebSocket channel
abstract class AbsWebsocketChannelService extends AbsWithLifeCycle
    with MixinWsMsgParserService, MixinWsMsgSenderService {
  /// Label used in HTTP logs for received messages
  static const _receivedMessageLabel = "RECEIVED";

  /// Label used in HTTP logs for sent messages
  static const _sentMessageLabel = "SENT";

  /// Label used in HTTP logs for error messages
  static const _errorMessageLabel = "ERROR";

  /// Default message displayed in HTTP logs when the message isn't a string
  static const _defaultDisplayedMessage = "data";

  /// This is the unique UUID of the client linked to this WebSocket channel
  final String clientUuid;

  /// This is the HTTP logging manager
  final HttpLoggingManager _httpLoggingManager;

  /// This is the WebSocket channel linked to a specific client
  final WebSocketChannel _webSocket;

  /// This is the callback called when the WebSocket channel is closed
  final void Function(String clientUuid) _onClose;

  /// On WebSocket message stream subscription
  StreamSubscription? _onMessageSub;

  /// Indicates if the WebSocket channel is closed
  bool isClosed;

  /// Class constructor
  AbsWebsocketChannelService({
    required WebSocketChannel webSocket,
    required HttpLoggingManager httpLoggingManager,
    required void Function(String clientUuid) onClose,
  }) : _webSocket = webSocket,
       _httpLoggingManager = httpLoggingManager,
       clientUuid = const Uuid().v1(),
       _onClose = onClose,
       isClosed = false;

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: clientUuid,
        route: "/",
        method: "/",
        logLevel: Level.debug,
        message: "WebSocket client: $clientUuid start listening",
      ),
    );
    _onMessageSub = _webSocket.stream.listen(
      onRawMessageReceived,
      onDone: disposeLifeCycle,
      onError: _onWebSocketCloseError,
    );
  }

  /// {@macro act_websocket_core.MixinWsMsgParserService.onRawMessageReceived}
  @protected
  @override
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<void> onRawMessageReceived(dynamic message) async {
    await super.onRawMessageReceived(message);

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: clientUuid,
        route: "/",
        method: _receivedMessageLabel,
        logLevel: Level.trace,
        message: (message is String) ? message : _defaultDisplayedMessage,
      ),
    );
  }

  /// {@macro act_websocket_core.MixinWsMsgParserService.sendRawMessage}
  @override
  // The message received can be string or binaries
  // ignore: avoid_annotating_with_dynamic
  Future<bool> sendRawMessage(dynamic message) async {
    if (isClosed) {
      return false;
    }

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: clientUuid,
        route: "/",
        method: _sentMessageLabel,
        logLevel: Level.trace,
        message: (message is String) ? message : _defaultDisplayedMessage,
      ),
    );

    var isOk = true;
    try {
      _webSocket.sink.add(message);
    } catch (error) {
      appLogger().e(
        "An error occurred when tried to send a message to the WebSocket client: $clientUuid",
      );
      isOk = false;
    }

    return isOk;
  }

  /// Called when an error occurred on the WebSocket channel
  Future<void> _onWebSocketCloseError(Object error, StackTrace stackTrace) async {
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: clientUuid,
        route: "/",
        method: _errorMessageLabel,
        logLevel: Level.warning,
        message: "WebSocket client: $clientUuid an error occurred $error",
      ),
    );

    return disposeLifeCycle();
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    isClosed = true;
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: clientUuid,
        route: "/",
        method: "/",
        logLevel: Level.debug,
        message: "WebSocket client: $clientUuid stop listening",
      ),
    );
    await _onMessageSub?.cancel();
    await _webSocket.sink.close(status.goingAway);
    _onClose(clientUuid);

    return super.disposeLifeCycle();
  }
}
