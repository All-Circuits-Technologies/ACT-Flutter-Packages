// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ble.dart';

/// The identifier of a characteristic the device of the tests does not carry.
const _anUnknownCharacteristic = "00002a2a-0000-1000-8000-00805f9b34fb";

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
    await manager.checkAndAskPermissions(displayContextualIfNeeded: false);
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

  /// A device of the application whose services were discovered.
  ///
  /// The device is left disconnected when [connected] says so.
  Future<BleDevice> aDevice({bool connected = true}) async {
    final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
    addTearDown(device.dispose);

    ble.services = [aDiscoveredService()];
    device.updateServicesAndChar(await FlutterReactiveBle().getDiscoveredServices(aDeviceId));

    if (connected) {
      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.connected,
            failure: null,
          ),
        ),
      );
      await pumpEventQueue();
    }

    return device;
  }

  group("BleGattService.readBleCharacteristic", () {
    test("answers the value the device holds", () async {
      final device = await aDevice();
      ble.readAnswer = const [4, 5, 6];

      final (error, value) = await manager.bleGattService.readBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.success);
      expect(value, const [4, 5, 6]);
    });

    test("refuses to read a device which is not connected", () async {
      final device = await aDevice(connected: false);

      final (error, value) = await manager.bleGattService.readBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.genericError);
      expect(value, isNull);
    });

    test("refuses to read a characteristic the device does not carry", () async {
      final device = await aDevice();

      final (error, value) = await manager.bleGattService.readBleCharacteristic(
        device,
        _anUnknownCharacteristic,
      );

      expect(error, CharacteristicsError.genericError);
      expect(value, isNull);
    });

    test("answers nothing when the device raises", () async {
      final device = await aDevice();
      ble.error = Exception("the device is confused");

      final (error, value) = await manager.bleGattService.readBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.genericError);
      expect(value, isNull);
    });

    test("says which permission is missing when the device refuses the reading", () async {
      final device = await aDevice();
      ble.error = Exception("GATT_INSUF_AUTHORIZATION or GATT_CONN_TIMEOUT");

      final (error, _) = await manager.bleGattService.readBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.missAuthorization);
    });
  });

  group("BleGattService.writeBleCharacteristic", () {
    test("writes the value to the device and waits for its answer", () async {
      final device = await aDevice();

      final error = await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
      );

      expect(error, CharacteristicsError.success);
      expect(ble.written.single.value, const [1, 2, 3]);
      expect(ble.written.single.withResponse, isTrue);
    });

    test("writes without waiting when it is asked to", () async {
      final device = await aDevice();

      await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
        withoutResponse: true,
      );

      expect(ble.written.single.withResponse, isFalse);
    });

    test("waits for the answer of an iOS device whatever it is asked", () async {
      globalGetIt()
        ..unregister<PlatformManager>()
        ..registerSingleton<PlatformManager>(FakePlatformManager.ios());
      final device = await aDevice();

      await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
        withoutResponse: true,
      );

      expect(ble.written.single.withResponse, isTrue);
    });

    test("refuses to write to a device which is not connected", () async {
      final device = await aDevice(connected: false);

      final error = await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
      );

      expect(error, CharacteristicsError.genericError);
      expect(ble.written, isEmpty);
    });

    test("takes the Bluetooth again when an Android device raises", () async {
      final device = await aDevice();
      ble.error = Exception("the device is confused");
      final before = ble.deinitCount;

      final error = await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
      );

      expect(error, CharacteristicsError.genericError);
      expect(ble.deinitCount, before + 1);
    });

    test("says that the pairing failed when an iOS device asks for encryption", () async {
      globalGetIt()
        ..unregister<PlatformManager>()
        ..registerSingleton<PlatformManager>(FakePlatformManager.ios());
      final device = await aDevice();
      ble.error = Exception("Encryption is insufficient");

      await manager.bleGattService.writeBleCharacteristic(
        device,
        aCharacteristicUuid.toString(),
        const [1, 2, 3],
      );

      expect(device.bondState, BondState.bondingFailed);
    });
  });

  group("BleGattService.subscribeBleNotification", () {
    test("listens to the characteristic of the device", () async {
      final device = await aDevice();

      final (error, stream) = await manager.bleGattService.subscribeBleNotification(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.success);
      expect(stream, isNotNull);

      final subscription = stream!.listen(null);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(ble.subscribed, [aCharacteristicUuid]);
    });

    test("refuses to listen to a device which is not connected", () async {
      final device = await aDevice(connected: false);

      final (error, stream) = await manager.bleGattService.subscribeBleNotification(
        device,
        aCharacteristicUuid.toString(),
      );

      expect(error, CharacteristicsError.genericError);
      expect(stream, isNull);
    });

    test("refuses to listen to a characteristic the device does not carry", () async {
      final device = await aDevice();

      final (error, _) = await manager.bleGattService.subscribeBleNotification(
        device,
        _anUnknownCharacteristic,
      );

      expect(error, CharacteristicsError.genericError);
      expect(ble.subscribed, isEmpty);
    });
  });

  group("BleGattService.getBleDevice", () {
    test("knows nothing of a device which was never scanned", () {
      expect(manager.bleGattService.getBleDevice(aDeviceId), isNull);
    });

    test("knows nothing of a device which has no identifier at all", () {
      expect(manager.bleGattService.getBleDevice(null), isNull);
    });
  });

  group("BleGattService.isScannedDevice", () {
    test("says that a device which was never scanned is unknown", () {
      expect(manager.bleGattService.isScannedDevice(aDeviceId), isFalse);
    });
  });

  group("BleGattService.lastConnectedDevice", () {
    test("knows no device before anything was connected", () {
      expect(manager.bleGattService.lastConnectedDevice, isNull);
    });
  });
}
