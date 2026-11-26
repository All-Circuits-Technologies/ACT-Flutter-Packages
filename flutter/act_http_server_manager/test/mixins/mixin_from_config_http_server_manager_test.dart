// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpLogging logging;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
  });

  tearDown(FakeAssets.stop);

  /// The configuration the server of an application which holds [configuration] runs on.
  Future<HttpServerConfig> aServerConfig(String configuration) async {
    FakeAssets.serve({"assets/config/default.yaml": configuration});
    final configManager = FakeServerConfig();
    await configManager.initLifeCycle();
    addTearDown(configManager.disposeLifeCycle);

    final manager = FakeConfiguredServerManager(configManager: configManager);

    return manager.readServerConfig(logging);
  }

  group("MixinFromConfigHttpServerManager.getServerConfig", () {
    test("runs the server the way the configuration of the application says", () async {
      final config = await aServerConfig('''
http:
  server:
    name: an api
    hostname: 127.0.0.1
    port: 8080
    basePath: /api
''');

      expect(
        config,
        const HttpServerConfig(
          serverName: "an api",
          hostname: "127.0.0.1",
          port: 8080,
          basePath: "/api",
        ),
      );
    });

    test("answers on every address and on the http port when nothing says otherwise", () async {
      final config = await aServerConfig("http:\n  server:\n    name: an api");

      expect(config.hostname, "0.0.0.0");
      expect(config.port, 80);
      expect(config.basePath, isNull);
    });

    test("names the server for a configuration which does not name it", () async {
      final config = await aServerConfig("http:\n  server:\n    port: 8080");

      expect(config.serverName, "Http server");
    });
  });
}
