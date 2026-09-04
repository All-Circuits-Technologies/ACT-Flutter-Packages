// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager_ui/act_ble_manager_ui.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

import '../fakes/fake_ble_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late FakeAppLifeCycleManager lifeCycle;
  late BleManager manager;
  late FakeBleConfigManager config;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();
    FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FakeAppSettings.serve();

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager())
      ..registerSingleton<FakeBleRouterManager>(FakeBleRouterManager());

    final contextualViews = ContextualViewsBuilder<FakeBleRouterManager>(
      viewBuilder: FakeBleViewBuilder(),
    ).factory();
    await contextualViews.initLifeCycle();
    globalGetIt().registerSingleton<ContextualViewsManager>(contextualViews);
    addTearDown(contextualViews.disposeLifeCycle);

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);
    await manager.initLifeCycle();
    await ble.tellStatus(BleStatus.ready);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAppSettings.stop();
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The bloc of a page which displays the devices which are scanned.
  ///
  /// Only the devices [filter] answers true for are displayed, when a filter is given.
  Future<BleScannedDevicesBloc> aBloc({FilterDevice? filter}) async {
    final bloc = BleScannedDevicesBloc(isDeviceHasToBeDisplayed: filter);
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  /// A device of the application, as the scanning answers it.
  BleScannedDevice aScannedDevice({String id = aDeviceId, String name = "a device"}) =>
      BleScannedDevice(aDiscoveredDevice(id: id, name: name));

  /// Tells the bloc that [device] was scanned, or is gone when [type] says so.
  Future<void> tellScanned(
    BleScannedDevicesBloc bloc,
    BleScannedDevice device, {
    BleScanUpdateType type = BleScanUpdateType.addDevice,
  }) async {
    bloc.add(BleScanUpdateStatusEvent(scanUpdateStatus: BleScanUpdateStatus(type, device)));
    await pumpEventQueue();
  }

  group("BleScannedDevicesBloc", () {
    test("starts the scanning of the devices as soon as it is built", () async {
      final bloc = await aBloc();

      expect(bloc.state.isScanActive, isTrue);
      expect(bloc.state.isBluetoothActive, isTrue);
    });

    test("displays a device which was scanned", () async {
      final bloc = await aBloc();

      await tellScanned(bloc, aScannedDevice());

      expect(bloc.state.devices.map((device) => device.id), [aDeviceId]);
    });

    test("displays a device which was scanned once, whatever the number of updates", () async {
      final bloc = await aBloc();
      final device = aScannedDevice();

      await tellScanned(bloc, device);
      await tellScanned(bloc, device, type: BleScanUpdateType.updateDevice);

      expect(bloc.state.devices.length, 1);
    });

    test("displays nothing of a device the page filters out", () async {
      final bloc = await aBloc(filter: (device) => device.name == "a wanted device");

      await tellScanned(bloc, aScannedDevice());

      expect(bloc.state.devices, isEmpty);
    });

    test("displays a device the page asked for", () async {
      final bloc = await aBloc(filter: (device) => device.name == "a wanted device");

      await tellScanned(bloc, aScannedDevice(name: "a wanted device"));

      expect(bloc.state.devices.length, 1);
    });

    test("stops displaying a device which is gone", () async {
      final bloc = await aBloc();
      final device = aScannedDevice();
      await tellScanned(bloc, device);

      await tellScanned(bloc, device, type: BleScanUpdateType.removeDevice);

      expect(bloc.state.devices, isEmpty);
    });

    test("says nothing of a device which is gone and was never displayed", () async {
      final bloc = await aBloc();
      await tellScanned(bloc, aScannedDevice());
      final before = bloc.state;

      await tellScanned(
        bloc,
        aScannedDevice(id: "another-device"),
        type: BleScanUpdateType.removeDevice,
      );

      expect(bloc.state, same(before));
    });

    test("displays nothing once the page asks for the list to be cleared", () async {
      final bloc = await aBloc();
      await tellScanned(bloc, aScannedDevice());

      bloc.add(const ClearScannedDevicesListEvent());
      await pumpEventQueue();

      expect(bloc.state.devices, isEmpty);
      expect(bloc.state.isScanActive, isTrue);
    });

    test("stops the scanning when the page asks for it", () async {
      final bloc = await aBloc();

      bloc.add(const StopBleScanEvent());
      await pumpEventQueue();

      expect(bloc.state.isScanActive, isFalse);
    });

    test("starts the scanning again when the page asks for it", () async {
      final bloc = await aBloc();
      bloc.add(const StopBleScanEvent());
      await pumpEventQueue();

      bloc.add(const StartBleScanEvent());
      await pumpEventQueue();

      expect(bloc.state.isScanActive, isTrue);
    });

    test("tells the page when the user switches the Bluetooth off", () async {
      final bloc = await aBloc();

      await ble.tellStatus(BleStatus.poweredOff);
      await pumpEventQueue();

      expect(bloc.state.isBluetoothActive, isFalse);
      expect(bloc.state.isScanActive, isTrue);
    });

    test("tells the page when the user switches the Bluetooth on again", () async {
      final bloc = await aBloc();
      await ble.tellStatus(BleStatus.poweredOff);
      await pumpEventQueue();

      await ble.tellStatus(BleStatus.ready);
      await pumpEventQueue();

      expect(bloc.state.isBluetoothActive, isTrue);
    });

    test("scans nothing when the Bluetooth of the device is off at start", () async {
      await ble.tellStatus(BleStatus.poweredOff);
      await pumpEventQueue();

      final bloc = BleScannedDevicesBloc();
      addTearDown(bloc.close);
      await pumpEventQueue();

      expect(bloc.state.isBluetoothActive, isFalse);
      expect(bloc.state.isScanActive, isFalse);
    });
  });
}
