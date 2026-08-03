// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_websocket_client_manager/act_websocket_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// The configuration of an application which talks to a server on the loopback.
final _config = WsClientManagerConfig(
  uri: Uri.parse("ws://a.host:8080"),
  autoReconnectEnabled: true,
  autoReconnectInitDuration: const Duration(milliseconds: 500),
  autoReconnectMaxDuration: const Duration(seconds: 3),
  startWsAtManagerInit: true,
  msgParsers: const [],
  protocols: const [],
  logReceivedMsg: false,
);

void main() {
  group("WsClientManagerConfig.copyWith", () {
    test("keeps the values the caller did not give", () {
      expect(_config.copyWith(), _config);
    });

    test("replaces the values the caller gave", () {
      final copy = _config.copyWith(
        uri: Uri.parse("ws://another.host"),
        autoReconnectEnabled: false,
        logReceivedMsg: true,
      );

      expect(copy.uri, Uri.parse("ws://another.host"));
      expect(copy.autoReconnectEnabled, isFalse);
      expect(copy.logReceivedMsg, isTrue);
      expect(copy.autoReconnectMaxDuration, _config.autoReconnectMaxDuration);
    });

    test("replaces the protocols and the parsers the caller gave", () {
      final copy = _config.copyWith(protocols: const ["a protocol"]);

      expect(copy.protocols, ["a protocol"]);
    });
  });

  group("WsClientManagerConfig", () {
    test("tells two configurations which differ apart", () {
      expect(_config, isNot(_config.copyWith(startWsAtManagerInit: false)));
    });
  });
}
