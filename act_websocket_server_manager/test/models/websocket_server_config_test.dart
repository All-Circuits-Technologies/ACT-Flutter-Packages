// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_websocket_server_manager/act_websocket_server_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("WebsocketServerConfig", () {
    test("decides nothing for a server which was given no configuration", () {
      const config = WebsocketServerConfig();

      expect(config.protocols, isNull);
      expect(config.allowedOrigins, isNull);
      expect(config.pingInterval, isNull);
    });

    test("is the same configuration as another one which decides the same", () {
      expect(
        const WebsocketServerConfig(protocols: ["a.protocol"], pingInterval: Duration(seconds: 5)),
        const WebsocketServerConfig(protocols: ["a.protocol"], pingInterval: Duration(seconds: 5)),
      );
    });

    test("is another configuration as soon as one of them differs", () {
      expect(
        const WebsocketServerConfig(allowedOrigins: ["https://an.origin"]),
        isNot(const WebsocketServerConfig(allowedOrigins: ["https://another.origin"])),
      );
    });
  });
}
