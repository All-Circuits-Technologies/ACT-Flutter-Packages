// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_aws_iot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late AmplifyCognitoService cognito;
  FakeAwsIotConfigManager? config;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    cognito = AmplifyCognitoService();
  });

  tearDown(() async {
    FakeAssets.stop();
    await config?.disposeLifeCycle();
    config = null;
    await globalManager.reset();
  });

  /// The configuration of an application whose configuration file holds [content].
  Future<void> anApplicationConfiguredWith(String content) async {
    config = await FakeAwsIotConfigManager.withContent(content);
    globalGetIt().registerSingleton<FakeAwsIotConfigManager>(config!);
  }

  /// The configuration of the server, as it is read from the application.
  AwsIotMqttConfigModel? read({Duration? signerValidityDuration, int? mqttPort}) =>
      AwsIotMqttConfigModel.get<FakeAwsIotConfigManager>(
        cognitoService: cognito,
        signerValidityDuration: signerValidityDuration,
        mqttPort: mqttPort,
      );

  group("AwsIotMqttConfigModel.get", () {
    test("reads where the server is from the configuration of the application", () async {
      await anApplicationConfiguredWith(anAwsIotConf);

      final model = read();

      expect(model?.endpoint, "an-endpoint.example.com");
      expect(model?.region, "eu-west-1");
    });

    test("says nothing of a server whose region the application does not name", () async {
      await anApplicationConfiguredWith("aws:\n  iot:\n    endpoint: an-endpoint.example.com");

      expect(read(), isNull);
    });

    test("says nothing of a server whose address the application does not name", () async {
      await anApplicationConfiguredWith("aws:\n  iot:\n    region: eu-west-1");

      expect(read(), isNull);
    });

    test("reaches the server over its usual port and signs for a quarter of an hour", () async {
      await anApplicationConfiguredWith(anAwsIotConf);

      final model = read();

      expect(model?.mqttPort, 443);
      expect(model?.signerValidityDuration, const Duration(minutes: 15));
    });

    test("takes the port and the validity the caller asked for", () async {
      await anApplicationConfiguredWith(anAwsIotConf);

      final model = read(mqttPort: 8883, signerValidityDuration: const Duration(minutes: 2));

      expect(model?.mqttPort, 8883);
      expect(model?.signerValidityDuration, const Duration(minutes: 2));
    });

    test("reads the same configuration twice as the same one", () async {
      await anApplicationConfiguredWith(anAwsIotConf);

      expect(read(mqttPort: 1883), read(mqttPort: 1883));
    });

    test("reads a configuration whose port differs as another one", () async {
      await anApplicationConfiguredWith(anAwsIotConf);

      expect(read(mqttPort: 1883), isNot(read(mqttPort: 8883)));
    });
  });
}
