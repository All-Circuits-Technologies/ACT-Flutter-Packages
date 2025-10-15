// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_websocket_core/act_websocket_core.dart';
import 'package:equatable/equatable.dart';

/// This is the config of the WebSocket client manager
class WsClientManagerConfig extends Equatable {
  /// This is the url of the WebSocket server
  final Uri uri;

  /// Says if the auto reconnection of the WebSocket is enabled or not.
  final bool autoReconnectEnabled;

  /// This is the init duration of the the WebSocket auto reconnection
  final Duration autoReconnectInitDuration;

  /// This is the max duration of the the WebSocket auto reconnection
  final Duration autoReconnectMaxDuration;

  /// If true, we try to connect the WebSocket at the manager init
  final bool startWsAtManagerInit;

  /// Get a list of msg parsers
  final List<MixinWsMsgParserService> msgParsers;

  /// This is the list of the protocols to use with the WebSocket
  final List<String> protocols;

  /// If true, we log all the message received by the WebSocket as trace level
  final bool logReceivedMsg;

  /// Class constructor
  const WsClientManagerConfig({
    required this.uri,
    required this.autoReconnectEnabled,
    required this.autoReconnectInitDuration,
    required this.autoReconnectMaxDuration,
    required this.startWsAtManagerInit,
    required this.msgParsers,
    required this.protocols,
    required this.logReceivedMsg,
  });

  /// Create a copy of the current config with some new values
  WsClientManagerConfig copyWith({
    Uri? uri,
    bool? autoReconnectEnabled,
    Duration? autoReconnectInitDuration,
    Duration? autoReconnectMaxDuration,
    bool? startWsAtManagerInit,
    List<MixinWsMsgParserService>? msgParsers,
    List<String>? protocols,
    bool? logReceivedMsg,
  }) => WsClientManagerConfig(
    uri: uri ?? this.uri,
    autoReconnectEnabled: autoReconnectEnabled ?? this.autoReconnectEnabled,
    autoReconnectInitDuration: autoReconnectInitDuration ?? this.autoReconnectInitDuration,
    autoReconnectMaxDuration: autoReconnectMaxDuration ?? this.autoReconnectMaxDuration,
    startWsAtManagerInit: startWsAtManagerInit ?? this.startWsAtManagerInit,
    msgParsers: msgParsers ?? this.msgParsers,
    protocols: protocols ?? this.protocols,
    logReceivedMsg: logReceivedMsg ?? this.logReceivedMsg,
  );

  /// Class properties
  @override
  List<Object?> get props => [
    uri,
    autoReconnectEnabled,
    autoReconnectInitDuration,
    autoReconnectMaxDuration,
    startWsAtManagerInit,
    msgParsers,
    protocols,
    logReceivedMsg,
  ];
}
