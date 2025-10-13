// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// Extends the [AbstractConfigManager] to add config variables which will be used by the
/// WebSocketClientManager
mixin MixinWebsocketClientConfig on AbstractConfigManager {
  /// This is the server FDQN to use when we try to connect to the default WebSocket server
  final websocketClientUrl = const NotNullParserConfigVar<Uri, String>.crashIfNull(
    "webSocket.client.url",
    parser: Uri.tryParse,
  );

  /// When true, we log all the message received by the WebSocket as trace level
  final websocketClientLogReceivedMsg = const NotNullableConfigVar(
    "webSocket.client.logReceivedMsg",
    defaultValue: false,
  );

  /// This is used to enable the WebSocket auto reconnection
  final websocketClientAutoRecoEnabled = const NotNullableConfigVar<bool>(
    "webSocket.client.autoReconnect.enable",
    defaultValue: true,
  );

  /// This is the initial duration in milliseconds of the WebSocket auto reconnection
  final websocketClientAutoRecoInitDurationInMs = const NotNullParserConfigVar<Duration, int>(
    "webSocket.client.autoReconnect.initDuration",
    parser: DurationUtility.parseFromMilliseconds,
    defaultValue: Duration(milliseconds: 500),
  );

  /// This is the max duration in milliseconds of the WebSocket auto reconnection
  final websocketClientAutoRecoMaxDurationInMs = const NotNullParserConfigVar<Duration, int>(
    "webSocket.client.autoReconnect.maxDuration",
    parser: DurationUtility.parseFromMilliseconds,
    defaultValue: Duration(seconds: 3),
  );
}
