// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ws_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  /// The configuration of an application whose file says [content].
  Future<FakeWsServerConfig> aConfig([String content = "logs:\n  level: warning"]) async {
    FakeAssets.serve({"assets/config/default.yaml": content});

    final config = FakeWsServerConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinWebsocketServerConfig", () {
    test("reads where the WebSocket server of an application answers", () async {
      final config = await aConfig(
        'webSocket:\n  server:\n    name: "a server"\n    hostname: "127.0.0.1"\n'
        '    port: 8080\n    basePath: "/api"',
      );

      expect(config.wsServerName.load(), "a server");
      expect(config.wsServerHostname.load(), "127.0.0.1");
      expect(config.wsServerPort.load(), 8080);
      expect(config.wsServerBasePath.load(), "/api");
    });

    test("answers on every address and on the http port when nothing is named", () async {
      final config = await aConfig();

      expect(config.wsServerName.load(), "WebSocket server");
      expect(config.wsServerHostname.load(), "0.0.0.0");
      expect(config.wsServerPort.load(), 80);
      expect(config.wsServerBasePath.load(), isNull);
    });
  });

  group("MixinFromConfigWsServerManager", () {
    test("builds the configuration of the server from the one of the application", () async {
      final configManager = await aConfig(
        'webSocket:\n  server:\n    name: "a server"\n    hostname: "127.0.0.1"\n'
        '    port: 8080\n    basePath: "/api"',
      );
      final manager = FakeConfiguredWsServerManager(configManager: configManager);
      final logging = FakeHttpLogging();
      await logging.initLifeCycle();

      final serverConfig = await manager.readServerConfig(logging);

      expect(serverConfig.serverName, "a server");
      expect(serverConfig.hostname, "127.0.0.1");
      expect(serverConfig.port, 8080);
      expect(serverConfig.basePath, "/api");
    });
  });
}
