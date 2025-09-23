// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_web_socket_manager/src/mixins/mixin_ws_msg_parser_service.dart';
import 'package:equatable/equatable.dart';

/// This is the config of the Web Socket manager
class WsManagerConfig extends Equatable {
  /// This is the url of the web socket server
  final Uri uri;

  /// Says if the auto reconnection of the web socket is enabled or not.
  final bool autoReconnectEnabled;

  /// This is the init duration of the the web socket auto reconnection
  final Duration autoReconnectInitDuration;

  /// This is the max duration of the the web socket auto reconnection
  final Duration autoReconnectMaxDuration;

  /// If true, we try to connect the web socket at the manager init
  final bool startWsAtManagerInit;

  /// Get a list of msg parsers
  final List<MixinWsMsgParserService> msgParsers;

  /// This is the list of the protocols to use with the web socket
  final List<String> protocols;

  /// If true, we log all the message received by the websocket as trace level
  final bool logReceivedMsg;

  /// Class constructor
  const WsManagerConfig({
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
  WsManagerConfig copyWith({
    Uri? uri,
    bool? autoReconnectEnabled,
    Duration? autoReconnectInitDuration,
    Duration? autoReconnectMaxDuration,
    bool? startWsAtManagerInit,
    List<MixinWsMsgParserService>? msgParsers,
    List<String>? protocols,
    bool? logReceivedMsg,
  }) => WsManagerConfig(
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
