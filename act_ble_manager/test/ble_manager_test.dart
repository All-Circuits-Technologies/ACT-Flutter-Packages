// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

import 'fakes/fake_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late FakeAppLifeCycleManager lifeCycle;
  late FakeBleViewBuilder views;
  late FakeBleConfigManager config;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();
    FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    views = FakeBleViewBuilder();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FakeAppSettings.serve();

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager())
      ..registerSingleton<FakeBleRouterManager>(FakeBleRouterManager());

    final contextualViews = ContextualViewsBuilder<FakeBleRouterManager>(
      viewBuilder: views,
    ).factory();
    await contextualViews.initLifeCycle();
    globalGetIt().registerSingleton<ContextualViewsManager>(contextualViews);
    addTearDown(contextualViews.disposeLifeCycle);

    config = await FakeBleConfigManager.withContent(aBleConf);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAppSettings.stop();
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The Bluetooth manager of an application, initialized.
  ///
  /// The Bluetooth of the device is in [status] when the manager starts.
  Future<BleManager> aManager({BleStatus status = BleStatus.ready}) async {
    final manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);
    await manager.initLifeCycle();
    await ble.tellStatus(status);
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("BleBuilder", () {
    test("depends on the logger, on the configuration and on the permissions", () {
      final builder = BleBuilder<FakeBleConfigManager>();

      expect(builder.dependsOn(), [LoggerManager, FakeBleConfigManager, PermissionsManager]);
    });
  });

  group("BleManager.getElement", () {
    test("stands for the Bluetooth of the device", () async {
      final manager = await aManager();

      expect(manager.getElement(), EnableServiceElement.ble);
    });
  });

  group("BleManager.getPermissionsConfig", () {
    test("asks for the permissions of the Bluetooth", () async {
      final manager = await aManager();

      final configs = manager.getPermissionsConfig();

      expect(configs.length, 1);
      expect(configs.single.element, PermissionElement.ble);
    });
  });

  group("BleManager.enabledStream", () {
    test("says that the Bluetooth is usable when the device says it is ready", () async {
      final manager = await aManager(status: BleStatus.poweredOff);
      final enabled = <bool>[];
      manager.enabledStream.listen(enabled.add);

      await ble.tellStatus(BleStatus.ready);
      await pumpEventQueue();

      expect(enabled, [true]);
      expect(manager.isEnabled, isTrue);
    });

    test("says that the Bluetooth is not usable when the device switches it off", () async {
      final manager = await aManager();
      final enabled = <bool>[];
      manager.enabledStream.listen(enabled.add);

      await ble.tellStatus(BleStatus.poweredOff);
      await pumpEventQueue();

      expect(enabled, [false]);
    });

    test("reads every state which is not ready as the Bluetooth being unusable", () async {
      final manager = await aManager(status: BleStatus.unauthorized);

      expect(manager.isEnabled, isFalse);
    });
  });

  group("BleManager.askForEnabling", () {
    test("asks nothing of the user when the Bluetooth is ready", () async {
      final manager = await aManager();

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isTrue);
      expect(views.displayed, isEmpty);
    });

    test("asks nothing of the user when the permissions are missing", () async {
      final manager = await aManager(status: BleStatus.unauthorized);

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(views.displayed, isEmpty);
    });

    test("asks nothing of a device which has no Bluetooth at all", () async {
      final manager = await aManager(status: BleStatus.unsupported);

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(views.displayed, isEmpty);
    });

    test("asks the user to switch the Bluetooth on", () async {
      final manager = await aManager(status: BleStatus.poweredOff);

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(views.displayed, [EnableServiceElement.ble]);
      expect(FakeAppSettings.opened, isNotEmpty);
    });

    test("says that the Bluetooth is usable once the user switched it on", () async {
      final manager = await aManager(status: BleStatus.poweredOff);
      FakeAppSettings.onOpened = () => ble.tellStatus(BleStatus.ready);

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isTrue);
      expect(views.displayed, [EnableServiceElement.ble]);
    });

    test("asks the user to switch the location on when that is what is missing", () async {
      final manager = await aManager(status: BleStatus.locationServicesDisabled);

      await manager.checkAndAskForEnabling();

      expect(views.displayed.first, EnableServiceElement.bleLocation);
    });

    test("asks nothing more when the user leaves the page", () async {
      views.userAgrees = false;
      final manager = await aManager(status: BleStatus.poweredOff);

      final enabled = await manager.checkAndAskForEnabling();

      expect(enabled, isFalse);
      expect(FakeAppSettings.opened, isEmpty);
    });
  });

  group("BleManager.reInitFlutterBle", () {
    test("gives the Bluetooth up and takes it again", () async {
      final manager = await aManager();
      final before = ble.deinitCount;

      await manager.reInitFlutterBle();

      expect(ble.deinitCount, before + 1);
    });

    test("tells the application that the Bluetooth was taken again", () async {
      final manager = await aManager();
      var told = 0;
      manager.libReInitStream.listen((_) => told++);

      await manager.reInitFlutterBle();
      await pumpEventQueue();

      expect(told, 1);
    });

    test("keeps following the state of the Bluetooth of the device", () async {
      final manager = await aManager();
      await manager.reInitFlutterBle();

      await ble.tellStatus(BleStatus.poweredOff);
      await pumpEventQueue();

      expect(manager.isEnabled, isFalse);
    });
  });

  group("BleManager.disposeLifeCycle", () {
    test("stops telling the application that the Bluetooth was taken again", () async {
      final manager = BleManager(confGetter: () => config);
      globalGetIt().registerSingleton<BleManager>(manager);
      await manager.initLifeCycle();
      var closed = false;
      manager.libReInitStream.listen(null, onDone: () => closed = true);

      await manager.disposeLifeCycle();
      await pumpEventQueue();

      expect(closed, isTrue);
    });
  });
}
