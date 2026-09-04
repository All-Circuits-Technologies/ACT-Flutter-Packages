// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_location_manager/act_location_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    hide ServiceStatus;

import 'fakes/fake_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeGeolocatorPlatform device;
  late FakeAppLifeCycleManager lifeCycle;
  late FakeLocationViewBuilder views;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    device = FakeGeolocatorPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    views = FakeLocationViewBuilder();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FakeAppSettings.serve();

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager())
      ..registerSingleton<FakeLocationRouterManager>(FakeLocationRouterManager());

    final contextualViews = ContextualViewsBuilder<FakeLocationRouterManager>(
      viewBuilder: views,
    ).factory();
    await contextualViews.initLifeCycle();
    globalGetIt().registerSingleton<ContextualViewsManager>(contextualViews);
    addTearDown(contextualViews.disposeLifeCycle);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAppSettings.stop();
    await device.close();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The location manager of an application, initialized.
  Future<FakeLocationManager> aManager({
    LocationInitConfig config = const LocationInitConfig.defaultConfig(),
  }) async {
    final manager = FakeLocationManager(config: config);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("LocationBuilder", () {
    test("depends on the manager of the permissions and on the logger", () {
      expect(LocationBuilder().dependsOn(), [PermissionsManager, LoggerManager]);
    });
  });

  group("LocationInitConfig", () {
    test("asks for the location while the application is used, at a reduced accuracy", () {
      const config = LocationInitConfig.defaultConfig();

      expect(config.accuracy, LocationAccuracy.reduced);
      expect(config.isLocationUsageAlways, isFalse);
      expect(config.timeLimitWhenGettingPosition, const Duration(seconds: 10));
    });

    test("is the same configuration as one which says the same things", () {
      expect(
        const LocationInitConfig(accuracy: LocationAccuracy.best, isLocationUsageAlways: true),
        const LocationInitConfig(accuracy: LocationAccuracy.best, isLocationUsageAlways: true),
      );
    });

    test("is not the same configuration as one of another accuracy", () {
      expect(
        const LocationInitConfig.defaultConfig(),
        isNot(
          const LocationInitConfig(accuracy: LocationAccuracy.best, isLocationUsageAlways: false),
        ),
      );
    });
  });

  group("LocationManager.initLifeCycle", () {
    test("reads whether the location of the device is switched on", () async {
      device.serviceEnabled = true;

      final manager = await aManager();

      expect(manager.isEnabled, isTrue);
    });

    test("says that the location is off when the device says so", () async {
      device.serviceEnabled = false;

      final manager = await aManager();

      expect(manager.isEnabled, isFalse);
    });
  });

  group("LocationManager.getPermissionsConfig", () {
    test("asks for the location while the application is used", () async {
      final manager = await aManager();

      final configs = manager.permissions();

      expect(configs.length, 1);
      expect(configs.single.element, PermissionElement.locationWhenInUse);
      expect(configs.single.whenAskingCheckRationale, isTrue);
    });

    test("asks for the location at all times when the application needs it", () async {
      final manager = await aManager(
        config: const LocationInitConfig(
          accuracy: LocationAccuracy.best,
          isLocationUsageAlways: true,
        ),
      );

      final configs = manager.permissions();

      expect(configs.map((config) => config.element), [
        PermissionElement.locationAlways,
        PermissionElement.locationWhenInUse,
      ]);
      expect(configs.first.whenAskingDependsOn, [PermissionElement.locationWhenInUse]);
    });

    test("sends an iOS user to the settings for the location at all times", () async {
      globalGetIt()
        ..unregister<PlatformManager>()
        ..registerSingleton<PlatformManager>(FakePlatformManager.ios());
      final manager = await aManager(
        config: const LocationInitConfig(
          accuracy: LocationAccuracy.best,
          isLocationUsageAlways: true,
        ),
      );

      expect(manager.permissions().first.whenAskingForceGoToSettings, isTrue);
    });

    test("asks an Android user for the location at all times in the application", () async {
      final manager = await aManager(
        config: const LocationInitConfig(
          accuracy: LocationAccuracy.best,
          isLocationUsageAlways: true,
        ),
      );

      expect(manager.permissions().first.whenAskingForceGoToSettings, isFalse);
    });
  });

  group("LocationManager.enabledStream", () {
    test("tells the application when the location of the device is switched on", () async {
      device.serviceEnabled = false;
      final manager = await aManager();
      final enabled = <bool>[];
      manager.enabledStream.listen(enabled.add);

      await device.tellService(ServiceStatus.enabled);
      await pumpEventQueue();

      expect(enabled, [true]);
    });

    test("tells the application when the location of the device is switched off", () async {
      final manager = await aManager();
      final enabled = <bool>[];
      manager.enabledStream.listen(enabled.add);

      await device.tellService(ServiceStatus.disabled);
      await pumpEventQueue();

      expect(enabled, [false]);
    });

    test("keeps following the location of the device after an error", () async {
      final manager = await aManager();

      await device.tellError(Exception("the device is confused"));
      await device.tellService(ServiceStatus.disabled);
      await pumpEventQueue();

      expect(manager.errors.length, 1);
      expect(manager.isEnabled, isFalse);
    });
  });

  group("LocationManager.askForEnabling", () {
    test("asks nothing of the user when the location is already switched on", () async {
      final manager = await aManager();

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isTrue);
      expect(views.displayed, isEmpty);
    });

    test("sends the user to the settings of the device", () async {
      device.serviceEnabled = false;
      final manager = await aManager();
      lifeCycle.waitCount = 0;

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(views.displayed.single.uniqueKey, contains("enable_service"));
      expect(lifeCycle.waitCount, 1);
      expect(FakeAppSettings.opened, isNotEmpty);
    });

    test("says that the location is switched on when the user switched it on", () async {
      device.serviceEnabled = false;
      final manager = await aManager();
      views.userAgrees = true;
      device.serviceEnabled = true;

      expect(await manager.checkAndAskForEnabling(), isTrue);
    });

    test("asks nothing more when the user leaves the page", () async {
      device.serviceEnabled = false;
      final manager = await aManager();
      views.userAgrees = false;

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(lifeCycle.waitCount, 0);
    });
  });

  group("LocationManager.getCurrentPosition", () {
    test("answers the position of the device", () async {
      permissions.grantEverything();
      final manager = await aManager();
      device.position = aPosition(latitude: 48.5);

      final position = await manager.getCurrentPosition();

      expect(position?.latitude, 48.5);
    });

    test("asks the device at the accuracy of the configuration", () async {
      permissions.grantEverything();
      final manager = await aManager(
        config: const LocationInitConfig(
          accuracy: LocationAccuracy.best,
          isLocationUsageAlways: false,
          timeLimitWhenGettingPosition: Duration(seconds: 3),
        ),
      );

      await manager.getCurrentPosition();

      expect(device.asked.single?.accuracy, LocationAccuracy.best);
      expect(device.asked.single?.timeLimit, const Duration(seconds: 3));
    });

    test("asks the device at the accuracy it is given", () async {
      permissions.grantEverything();
      final manager = await aManager();

      await manager.getCurrentPosition(
        overrideDefaultAccuracy: LocationAccuracy.high,
        overrideDefaultTimeLimit: const Duration(seconds: 1),
      );

      expect(device.asked.single?.accuracy, LocationAccuracy.high);
      expect(device.asked.single?.timeLimit, const Duration(seconds: 1));
    });

    test("answers nothing when the permissions are refused", () async {
      permissions.answerToRequest = PermissionStatus.denied;
      final manager = await aManager();

      expect(await manager.getCurrentPosition(), isNull);
      expect(device.asked, isEmpty);
    });

    test("answers nothing when the device raises", () async {
      permissions.grantEverything();
      final manager = await aManager();
      device.error = Exception("no satellite in sight");

      expect(await manager.getCurrentPosition(), isNull);
    });

    test("says that the location is off when the device says it is disabled", () async {
      permissions.grantEverything();
      final manager = await aManager();
      device.error = const LocationServiceDisabledException();

      expect(await manager.getCurrentPosition(), isNull);
      expect(manager.isEnabled, isFalse);
    });

    test("asks the user for nothing when it is told not to", () async {
      final manager = await aManager();

      expect(await manager.getCurrentPosition(askPermissionToUser: false), isNull);
      expect(views.displayed, isEmpty);
    });
  });

  group("LocationManager.getLastKnownPosition", () {
    test("answers the position the device remembers", () async {
      permissions.grantEverything();
      final manager = await aManager();
      device.position = aPosition(longitude: -1.2);

      final position = await manager.getLastKnownPosition();

      expect(position?.longitude, -1.2);
    });

    test("answers nothing when the device remembers no position", () async {
      permissions.grantEverything();
      final manager = await aManager();

      expect(await manager.getLastKnownPosition(), isNull);
    });

    test("answers nothing when the permissions are refused", () async {
      permissions.answerToRequest = PermissionStatus.denied;
      final manager = await aManager();
      device.position = aPosition();

      expect(await manager.getLastKnownPosition(), isNull);
    });

    test("says that the location is off when the device says it is disabled", () async {
      permissions.grantEverything();
      final manager = await aManager();
      device.error = const LocationServiceDisabledException();

      expect(await manager.getLastKnownPosition(), isNull);
      expect(manager.isEnabled, isFalse);
    });
  });

  group("LocationManager.disposeLifeCycle", () {
    test("stops following the location of the device", () async {
      final manager = FakeLocationManager();
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();
      await device.tellService(ServiceStatus.disabled);
      await pumpEventQueue();

      expect(manager.isEnabled, isTrue);
    });
  });
}
