// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager_ui/act_ble_manager_ui.dart';
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
  late FakeBleManagerWithGatt manager;
  late FakeBleConfigManager config;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();
    FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = FakeBleManagerWithGatt(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);
    await manager.initLifeCycle();
    await ble.tellStatus(BleStatus.ready);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The bloc of a page which connects the application to a device.
  Future<BleConnectToDeviceBloc> aBloc({VoidCallback? onLowLevelConnect}) async {
    final bloc = BleConnectToDeviceBloc(onLowLevelConnectionCallback: onLowLevelConnect);
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  /// A device of the application, as the scanning answers it.
  BleScannedDevice aScannedDevice({String id = aDeviceId}) =>
      BleScannedDevice(aDiscoveredDevice(id: id));

  /// Has the page ask for [device] to be connected.
  Future<void> chooseDevice(BleConnectToDeviceBloc bloc, BleScannedDevice device) async {
    bloc.add(ChooseDeviceToConnectToEvent(deviceToConnectTo: device));
    await pumpEventQueue();
  }

  group("BleConnectToDeviceBloc", () {
    test("knows no device before the page asks for one", () async {
      final bloc = await aBloc();

      expect(bloc.state.device, isNull);
      expect(bloc.state.connectionState, DeviceConnectionState.disconnected);
      expect(bloc.state.bondState, BondState.unknown);
      expect(bloc.state.isConnectionFailed, isFalse);
    });

    test("connects to the device the page asked for", () async {
      final bloc = await aBloc();

      await chooseDevice(bloc, aScannedDevice());

      expect(manager.gatt.connected, [aDeviceId]);
      expect(bloc.state.device?.id, aDeviceId);
      expect(bloc.state.loading, isFalse);
    });

    test("tells the page that the device answered", () async {
      var told = 0;
      final bloc = await aBloc(onLowLevelConnect: () => told++);

      await chooseDevice(bloc, aScannedDevice());

      expect(told, 1);
    });

    test("says that the connection failed when the device refuses it", () async {
      final bloc = await aBloc();
      manager.gatt.connectAnswer = false;

      await chooseDevice(bloc, aScannedDevice());

      expect(bloc.state.isConnectionFailed, isTrue);
      expect(bloc.state.loading, isFalse);
    });

    test("connects nothing again to the device it is already connected to", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());
      manager.gatt.lastDevice = bloc.state.device;

      await chooseDevice(bloc, aScannedDevice());

      expect(manager.gatt.connected.length, 1);
    });

    test("tells the page when the device connects", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());

      await bloc.state.device!.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.connected,
            failure: null,
          ),
        ),
      );
      await pumpEventQueue();

      expect(bloc.state.connectionState, DeviceConnectionState.connected);
    });

    test("tells the page when the device is paired", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());

      bloc.state.device!.bondState = BondState.bonded;
      await pumpEventQueue();

      expect(bloc.state.bondState, BondState.bonded);
    });

    test("says that the page reads the connection while it is loading", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());

      bloc.add(const NewDeviceStateEvent(connectionState: DeviceConnectionState.connecting));
      await pumpEventQueue();

      expect(bloc.state.isLoadingOrConnecting, isTrue);
    });

    test("forgets the device when the page asks for a disconnection", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());

      bloc.add(const DisconnectDeviceEvent());
      await pumpEventQueue();

      expect(bloc.state.device, isNull);
      expect(bloc.state.connectionState, DeviceConnectionState.disconnected);
      expect(bloc.state.bondState, BondState.unknown);
    });

    test("stops following a device it no longer holds", () async {
      final bloc = await aBloc();
      await chooseDevice(bloc, aScannedDevice());
      final device = bloc.state.device!;
      bloc.add(const DisconnectDeviceEvent());
      await pumpEventQueue();

      device.bondState = BondState.bonded;
      await pumpEventQueue();

      expect(bloc.state.bondState, BondState.unknown);
    });
  });
}
