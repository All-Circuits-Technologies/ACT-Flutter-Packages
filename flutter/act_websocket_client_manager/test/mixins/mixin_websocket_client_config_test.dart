// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_websocket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  tearDown(FakeAssets.stop);

  /// The configuration of an application which holds [configuration].
  Future<FakeWsConfig> aConfig(String configuration) async {
    FakeAssets.serve({"assets/config/default.yaml": configuration});
    final config = FakeWsConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinWebsocketClientConfig.websocketClientUrl", () {
    test("reads the address of the server the application talks to", () async {
      final config = await aConfig("webSocket:\n  client:\n    url: ws://a.host:8080");

      expect(config.websocketClientUrl.load(), Uri.parse("ws://a.host:8080"));
    });

    test("crashes when the configuration names no server", () async {
      final config = await aConfig("webSocket:\n  client:\n    logReceivedMsg: true");

      expect(config.websocketClientUrl.load, throwsA(isA<Error>()));
    });
  });

  group("MixinWebsocketClientConfig", () {
    test("reads what the configuration says about the reconnection and the logs", () async {
      final config = await aConfig('''
webSocket:
  client:
    url: ws://a.host:8080
    logReceivedMsg: true
    autoReconnect:
      enable: false
      initDuration: 100
      maxDuration: 2000
''');

      expect(config.websocketClientLogReceivedMsg.load(), isTrue);
      expect(config.websocketClientAutoRecoEnabled.load(), isFalse);
      expect(
        config.websocketClientAutoRecoInitDurationInMs.load(),
        const Duration(milliseconds: 100),
      );
      expect(config.websocketClientAutoRecoMaxDurationInMs.load(), const Duration(seconds: 2));
    });

    test("reconnects and says nothing of the messages unless the configuration asks", () async {
      final config = await aConfig("webSocket:\n  client:\n    url: ws://a.host:8080");

      expect(config.websocketClientLogReceivedMsg.load(), isFalse);
      expect(config.websocketClientAutoRecoEnabled.load(), isTrue);
      expect(
        config.websocketClientAutoRecoInitDurationInMs.load(),
        const Duration(milliseconds: 500),
      );
      expect(config.websocketClientAutoRecoMaxDurationInMs.load(), const Duration(seconds: 3));
    });
  });
}
