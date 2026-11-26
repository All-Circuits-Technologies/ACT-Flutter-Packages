// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_aws_iot.dart';

/// The manager of the AWS IoT server of an application under test.
class FakeAwsIotManager
    extends AwsIotManager<FakeAuthManager, FakeAmplifyManager, FakeAwsIotConfigManager> {
  /// The service of Cognito the manager signs its requests with.
  final AmplifyCognitoService cognito = AmplifyCognitoService();

  /// The shadows the application follows for each of its devices.
  @override
  List<MixinAwsIotShadowEnum> get shadowTypesList => FakeShadow.values;

  /// The service of Cognito the manager signs its requests with.
  @override
  AmplifyCognitoService get cognitoService => cognito;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeInternetManager internet;
  late FakeAuthManager auth;
  FakeAwsIotConfigManager? config;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    internet = FakeInternetManager();
    auth = FakeAuthManager();
    await auth.initLifeCycle();

    globalGetIt()
      ..registerSingleton<InternetConnectivityManager>(internet)
      ..registerSingleton<FakeAuthManager>(auth);
  });

  tearDown(() async {
    FakeAssets.stop();
    await config?.disposeLifeCycle();
    config = null;
    await auth.disposeLifeCycle();
    await internet.close();
    await globalManager.reset();
  });

  /// The manager of an application whose configuration file holds [content].
  Future<FakeAwsIotManager> aManager({String content = anAwsIotConf}) async {
    config = await FakeAwsIotConfigManager.withContent(content);
    globalGetIt().registerSingleton<FakeAwsIotConfigManager>(config!);

    return FakeAwsIotManager();
  }

  group("AwsIotBuilder", () {
    test("depends on what the services of the server need", () {
      final builder =
          AwsIotBuilder<
            FakeAwsIotManager,
            FakeAuthManager,
            FakeAmplifyManager,
            FakeAwsIotConfigManager
          >(FakeAwsIotManager.new);

      expect(builder.dependsOn(), [
        LoggerManager,
        FakeAwsIotConfigManager,
        InternetConnectivityManager,
        FakeAmplifyManager,
        FakeAuthManager,
      ]);
    });
  });

  group("AwsIotManager.initLifeCycle", () {
    test("reaches the server the configuration of the application names", () async {
      final manager = await aManager();

      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      expect(manager.mqttService.config.endpoint, "an-endpoint.example.com");
      expect(manager.mqttService.config.region, "eu-west-1");
    });

    test("follows the shadows the application asked for", () async {
      final manager = await aManager();

      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      expect(manager.shadowsService.config.shadowsList, FakeShadow.values);
    });

    test("hands the shadows of the server over the same MQTT server it reaches", () async {
      final manager = await aManager();

      await manager.initLifeCycle();
      addTearDown(manager.disposeLifeCycle);

      expect(manager.shadowsService.mqttService, same(manager.mqttService));
    });

    test("raises when the configuration of the application does not name the server", () async {
      final manager = await aManager(content: "aws:\n  iot:\n    region: eu-west-1");

      await expectLater(manager.initLifeCycle(), throwsException);
    });
  });

  group("AwsIotManager.disposeLifeCycle", () {
    test("stops telling the application about the server", () async {
      final manager = await aManager();
      await manager.initLifeCycle();
      var closed = false;
      manager.mqttService.connectionStatusStream.listen(null, onDone: () => closed = true);

      await manager.disposeLifeCycle();

      expect(closed, isTrue);
    });
  });
}
