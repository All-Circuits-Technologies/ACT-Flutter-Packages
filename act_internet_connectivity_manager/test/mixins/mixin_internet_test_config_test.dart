// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_internet_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  tearDown(FakeAssets.stop);

  /// Builds the configuration of an application, with the section the test decides.
  Future<FakeInternetConfig> aConfig([String? section]) async {
    FakeAssets.serve({
      "${configPath}default.yaml": section ?? "logs:\n  level: warning",
    });
    final config = FakeInternetConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinInternetTestConfig", () {
    test("tests a public server unless the application names another one", () async {
      expect((await aConfig()).serverUriToTest.load().host, "www.google.com");
    });

    test("reads the server to test from the configuration", () async {
      final config = await aConfig(
        "internetConnectivity:\n  serverUriToTest: https://example.com",
      );

      expect(config.serverUriToTest.load(), Uri.parse("https://example.com"));
    });

    test("waits three hundred milliseconds between two answers by default", () async {
      expect((await aConfig()).testPeriod.load(), const Duration(milliseconds: 300));
    });

    test("reads the wait between two answers from the configuration", () async {
      final config = await aConfig("internetConnectivity:\n  testPeriodInMs: 50");

      expect(config.testPeriod.load(), const Duration(milliseconds: 50));
    });

    test("waits for three answers which agree by default", () async {
      expect((await aConfig()).constantValueNb.load(), 3);
    });

    test("tests nothing periodically unless the application asks for it", () async {
      expect((await aConfig()).periodicVerificationEnable.load(), isFalse);
    });

    test("reads the periodic test from the configuration", () async {
      final config = await aConfig(
        "internetConnectivity:\n"
        "  periodicVerification:\n"
        "    enable: true\n"
        "    minDurationInS: 5\n"
        "    maxDurationInS: 60",
      );

      expect(config.periodicVerificationEnable.load(), isTrue);
      expect(config.periodicVerificationMinDuration.load(), const Duration(seconds: 5));
      expect(config.periodicVerificationMaxDuration.load(), const Duration(seconds: 60));
    });

    test("waits between two seconds and twenty seconds by default", () async {
      final config = await aConfig();

      expect(config.periodicVerificationMinDuration.load(), const Duration(seconds: 2));
      expect(config.periodicVerificationMaxDuration.load(), const Duration(seconds: 20));
    });
  });
}
