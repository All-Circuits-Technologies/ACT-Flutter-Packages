// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_aws_iot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeInternetManager internet;
  late FakeAuthManager auth;
  late FakeAwsIotConfigManager config;
  late FakeMqttService mqtt;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    internet = FakeInternetManager();
    auth = FakeAuthManager();
    await auth.initLifeCycle();

    config = await FakeAwsIotConfigManager.withContent(anAwsIotConf);
    globalGetIt()
      ..registerSingleton<InternetConnectivityManager>(internet)
      ..registerSingleton<FakeAuthManager>(auth)
      ..registerSingleton<FakeAwsIotConfigManager>(config);

    mqtt = FakeMqttService(iotManagerLogsHelper: aLogsHelper(), config: aMqttConfig());
  });

  tearDown(() async {
    await mqtt.disposeLifeCycle();
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await auth.disposeLifeCycle();
    await internet.close();
    await globalManager.reset();
  });

  /// The service which follows the shadows [shadows] of every device of the application.
  Future<AwsIotShadowsService> aService({List<FakeShadow> shadows = FakeShadow.values}) async {
    final service = AwsIotShadowsService(
      config: AwsIotShadowsConfigModel(shadowsList: shadows),
      mqttService: mqtt,
      iotManagerLogsHelper: aLogsHelper(),
    );
    await service.initLifeCycle();
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  /// Has the server answer the state of every shadow it was asked for.
  Future<void> theServerAnswersTheStates({String thingName = aThingName}) async {
    for (final shadow in FakeShadow.values) {
      await mqtt.tellMessage(
        aTopicName(ShadowTopicsEnum.getAccepted, shadow: shadow, thingName: thingName),
        aShadowDoc(),
      );
    }
  }

  group("AwsIotShadowsService.addAndGetShadowsForDevice", () {
    test("follows every shadow the application asked for of a device", () async {
      final service = await aService();

      final shadows = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      expect(shadows.keys, FakeShadow.values);
    });

    test("names the topics of each shadow after the device and the shadow", () async {
      final service = await aService();

      final shadows = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      expect(
        shadows[FakeShadow.main]?.topicNames[ShadowTopicsEnum.get],
        aTopicName(ShadowTopicsEnum.get),
      );
      expect(
        shadows[FakeShadow.spare]?.topicNames[ShadowTopicsEnum.get],
        aTopicName(ShadowTopicsEnum.get, shadow: FakeShadow.spare),
      );
    });

    test("asks the server for the state of each shadow of the device", () async {
      final service = await aService();

      await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      expect(mqtt.lastPublishedOn(aTopicName(ShadowTopicsEnum.get)), "");
      expect(
        mqtt.lastPublishedOn(aTopicName(ShadowTopicsEnum.get, shadow: FakeShadow.spare)),
        "",
      );
    });

    test("follows the shadows of a device it already follows only once", () async {
      final service = await aService();
      final first = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      final again = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);

      expect(again[FakeShadow.main], same(first[FakeShadow.main]));
    });

    test("follows the shadows of each device of the application apart", () async {
      final service = await aService();

      final first = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      final second = await service.addAndGetShadowsForDevice<FakeShadow>("another-thing");
      await theServerAnswersTheStates();
      await theServerAnswersTheStates(thingName: "another-thing");

      expect(second[FakeShadow.main], isNot(same(first[FakeShadow.main])));
      expect(service.devices, [aThingName, "another-thing"]);
    });

    test("follows nothing of an application which asked for no shadow", () async {
      final service = await aService(shadows: const []);

      final shadows = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);

      expect(shadows, isEmpty);
      expect(mqtt.subscribed, isEmpty);
    });
  });

  group("AwsIotShadowsService.getShadow", () {
    test("hands over the shadow of a device it follows", () async {
      final service = await aService();
      final shadows = await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      expect(service.getShadow(aThingName, FakeShadow.main), same(shadows[FakeShadow.main]));
    });

    test("says nothing of a device it does not follow", () async {
      final service = await aService();

      expect(service.getShadow(aThingName, FakeShadow.main), isNull);
    });
  });

  group("AwsIotShadowsService.removeShadowsOfDevice", () {
    test("stops following the shadows of a device", () async {
      final service = await aService();
      await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      service.removeShadowsOfDevice(aThingName);

      expect(service.devices, isEmpty);
      expect(service.getShadow(aThingName, FakeShadow.main), isNull);
    });

    test("says nothing of a device it does not follow", () async {
      final service = await aService();
      await service.addAndGetShadowsForDevice<FakeShadow>(aThingName);
      await theServerAnswersTheStates();

      service.removeShadowsOfDevice("another-thing");

      expect(service.devices, [aThingName]);
    });
  });
}
