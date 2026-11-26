// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This class represent the configuration of the websocket server
class WebsocketServerConfig extends Equatable {
  /// The subprotocol is determined by looking at the client's
  /// `Sec-WebSocket-Protocol` header and selecting the first entry that also
  /// appears in [protocols]. If no subprotocols are shared between the client and
  /// the server, `null` will be passed instead and no subprotocol header will be
  /// sent to the client which may cause it to disconnect.
  final List<String>? protocols;

  /// If [allowedOrigins] is passed, browser connections will only be accepted if
  /// they're made by a script from one of the given origins. This ensures that
  /// malicious scripts running in the browser are unable to fake a WebSocket
  /// handshake. Note that non-browser programs can still make connections freely.
  /// See also the WebSocket spec's discussion of [origin considerations][].
  ///
  /// [origin considerations]: https://tools.ietf.org/html/rfc6455#section-10.2
  final List<String>? allowedOrigins;

  /// If [pingInterval] is specified, it will get passed to the created
  /// channel instance, enabling round-trip disconnect detection.
  final Duration? pingInterval;

  /// Class constructor
  const WebsocketServerConfig({this.protocols, this.allowedOrigins, this.pingInterval});

  /// Model properties
  @override
  List<Object?> get props => [protocols, allowedOrigins, pingInterval];
}
