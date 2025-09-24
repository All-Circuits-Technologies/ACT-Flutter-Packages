// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// Extends the [AbstractConfigManager] to add config variables which will be used by the
/// WebSocketManager
mixin MixinWebSocketConfig on AbstractConfigManager {
  /// This is the server FDQN to use when we try to connect to the default web socket server
  final webSocketUrl = const NotNullParserConfigVar<Uri, String>.crashIfNull(
    "webSocket.url",
    parser: Uri.tryParse,
  );

  /// When true, we log all the message received by the websocket as trace level
  final webSocketLogReceivedMsg = const NotNullableConfigVar(
    "webSocket.logReceivedMsg",
    defaultValue: false,
  );

  /// This is used to enable the web socket auto reconnection
  final webSocketAutoRecoEnabled = const NotNullableConfigVar<bool>(
    "webSocket.autoReconnect.enable",
    defaultValue: true,
  );

  /// This is the initial duration in milliseconds of the web socket auto reconnection
  final webSocketAutoRecoInitDurationInMs = const NotNullParserConfigVar<Duration, int>(
    "webSocket.autoReconnect.initDuration",
    parser: DurationUtility.parseFromMilliseconds,
    defaultValue: Duration(milliseconds: 500),
  );

  /// This is the max duration in milliseconds of the web socket auto reconnection
  final webSocketAutoRecoMaxDurationInMs = const NotNullParserConfigVar<Duration, int>(
    "webSocket.autoReconnect.maxDuration",
    parser: DurationUtility.parseFromMilliseconds,
    defaultValue: Duration(seconds: 3),
  );
}
