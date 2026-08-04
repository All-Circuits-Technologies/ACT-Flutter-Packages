// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ble.dart';

/// A characteristic of an application under test.
class _FakeCharacteristicInfo extends AbstractCharacteristicInfo {
  /// Class constructor
  const _FakeCharacteristicInfo({
    required super.name,
    required super.uuid,
    required super.scope,
    super.receiveType,
    super.sendType,
  });
}

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

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);
    await manager.initLifeCycle();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  group("BleScannedDevice", () {
    test("holds the name and the identifier the device advertised", () {
      final device = BleScannedDevice(aDiscoveredDevice(name: "a named device"));

      expect(device.id, aDeviceId);
      expect(device.name, "a named device");
    });

    test("was last seen when it was scanned", () {
      final before = DateTime.now().toUtc();

      final device = BleScannedDevice(aDiscoveredDevice());

      expect(device.lastSeenTs.isBefore(before), isFalse);
      expect(device.lastSeenTs.isUtc, isTrue);
    });

    test("takes the name of the device when it is scanned again", () {
      final device = BleScannedDevice(aDiscoveredDevice());

      final updated = device.updateFromDiscoveredDevice(
        aDiscoveredDevice(name: "another name"),
      );

      expect(updated, isTrue);
      expect(device.name, "another name");
    });

    test("refuses to take the name of another device", () {
      final device = BleScannedDevice(aDiscoveredDevice(name: "a named device"));

      final updated = device.updateFromDiscoveredDevice(
        aDiscoveredDevice(id: "another-device", name: "another name"),
      );

      expect(updated, isFalse);
      expect(device.name, "a named device");
    });
  });

  group("BleScanUpdateStatus", () {
    test("is the same update as one of the same kind on the same device", () {
      final device = BleScannedDevice(aDiscoveredDevice());

      expect(
        BleScanUpdateStatus(BleScanUpdateType.addDevice, device),
        BleScanUpdateStatus(BleScanUpdateType.addDevice, device),
      );
    });

    test("is not the same update as one of another kind", () {
      final device = BleScannedDevice(aDiscoveredDevice());

      expect(
        BleScanUpdateStatus(BleScanUpdateType.addDevice, device),
        isNot(BleScanUpdateStatus(BleScanUpdateType.removeDevice, device)),
      );
    });
  });

  group("BleDevice", () {
    test("holds the name and the identifier of the device which was scanned", () {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice(name: "a named device")));
      addTearDown(device.dispose);

      expect(device.name, "a named device");
      expect(device.id, aDeviceId);
      expect(device.isError(), isFalse);
    });

    test("says that a device which stands for nothing is on error", () {
      final device = BleDevice.error();
      addTearDown(device.dispose);

      expect(device.isError(), isTrue);
    });

    test("starts disconnected and knowing nothing of its pairing", () {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);

      expect(device.connectionState, DeviceConnectionState.disconnected);
      expect(device.bondState, BondState.unknown);
      expect(device.characteristics, isEmpty);
    });

    test("tells the application when its pairing changes", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
      final states = <BondState>[];
      device.bondStateStream.listen(states.add);

      device
        ..bondState = BondState.bonding
        ..bondState = BondState.bonded;
      await pumpEventQueue();

      expect(states, [BondState.bonding, BondState.bonded]);
    });

    test("says nothing when its pairing did not change", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()))
        ..bondState = BondState.bonded;
      addTearDown(device.dispose);
      final states = <BondState>[];
      device.bondStateStream.listen(states.add);

      device.bondState = BondState.bonded;
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test("holds every characteristic of the services which were discovered", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
      ble.services = [aDiscoveredService()];

      device.updateServicesAndChar(await FlutterReactiveBle().getDiscoveredServices(aDeviceId));

      expect(device.characteristics.length, 1);
      expect(device.findCharacteristic(aCharacteristicUuid.toString()), isNotNull);
    });

    test("finds no characteristic of an identifier it never discovered", () {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);

      expect(device.findCharacteristic("another-characteristic"), isNull);
    });

    test("forgets the characteristics it held when the services are discovered again", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
      ble.services = [aDiscoveredService()];
      device.updateServicesAndChar(await FlutterReactiveBle().getDiscoveredServices(aDeviceId));

      device.updateServicesAndChar(const []);

      expect(device.characteristics, isEmpty);
    });

    test("tells the application when the device connects", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
      final states = <DeviceConnectionState>[];
      device.connectionStateStream.listen(states.add);

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

      expect(states, [DeviceConnectionState.connected]);
      expect(device.connectionState, DeviceConnectionState.connected);
    });

    test("says nothing of the connection of another device", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
      final states = <DeviceConnectionState>[];
      device.connectionStateStream.listen(states.add);

      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: "another-device",
            connectionState: DeviceConnectionState.connected,
            failure: null,
          ),
        ),
      );
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test("reads a connection which failed as a disconnection", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
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

      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.connected,
            failure: GenericFailure<ConnectionError>(
              code: ConnectionError.unknown,
              message: "something went wrong",
            ),
          ),
        ),
      );
      await pumpEventQueue();

      expect(device.connectionState, DeviceConnectionState.disconnected);
    });

    test("says that it is disconnected when it is asked to disconnect", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);
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

      await device.disconnect();

      expect(device.connectionState, DeviceConnectionState.disconnected);
    });

    test("does nothing when it is asked to disconnect twice", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      addTearDown(device.dispose);

      await device.disconnect();

      expect(device.connectionState, DeviceConnectionState.disconnected);
    });

    test("stops telling the application about itself once it is disposed", () async {
      final device = BleDevice(BleScannedDevice(aDiscoveredDevice()));
      var closed = false;
      device.connectionStateStream.listen(null, onDone: () => closed = true);

      await device.dispose();
      await pumpEventQueue();

      expect(closed, isTrue);
    });
  });

  group("AbstractCharacteristicInfo", () {
    test("holds what an application says of a characteristic", () {
      const info = _FakeCharacteristicInfo(
        name: "a characteristic",
        uuid: "a-uuid",
        scope: CharacteristicScope.readWrite,
        receiveType: int,
        sendType: String,
      );

      expect(info.name, "a characteristic");
      expect(info.uuid, "a-uuid");
      expect(info.scope, CharacteristicScope.readWrite);
      expect(info.receiveType, int);
      expect(info.sendType, String);
    });

    test("says that a characteristic notifies nothing unless it is told otherwise", () {
      const info = _FakeCharacteristicInfo(
        name: "a characteristic",
        uuid: "a-uuid",
        scope: CharacteristicScope.readOnly,
      );

      expect(info.hasNotification, isFalse);
    });
  });

  group("CharacteristicsError", () {
    test("says which of its values are a success", () {
      expect(CharacteristicsError.success.isSuccess, isTrue);
      expect(CharacteristicsError.genericError.isSuccess, isFalse);
      expect(CharacteristicsError.missAuthorization.isSuccess, isFalse);
    });
  });
}
