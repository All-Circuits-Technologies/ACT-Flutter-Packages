// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

import 'fakes/fake_halo_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The time the tests wait for a device which answers nothing.
  const aShortTimeout = Duration(milliseconds: 20);

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late FakeAppLifeCycleManager lifeCycle;
  late BleManager manager;
  late FakeBleConfigManager config;
  late HaloBleConfig halo;
  late HaloBleCompanion companion;

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
    await ble.tellStatus(BleStatus.ready);
    await manager.checkAndAskPermissions(displayContextualIfNeeded: false);

    halo = aHaloConfig();
    companion = HaloBleCompanion(haloBleConfig: halo, bleManager: manager);
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await companion.onDisconnection();
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The device the companion talks to, once it is handed over.
  Future<BleDevice> aDeviceOfTheCompanion() async {
    final device = await aHaloDevice();
    await companion.onNewHaloBleDevice(device);
    await pumpHalo();

    return device;
  }

  /// Tells the application that the command characteristic of the device answered [value].
  Future<void> theDeviceNotifies(List<int> value) =>
      ble.tellNotification(halo.charJRequestToDeviceCmd.uuid, value);

  /// The bytes the tests write to the device.
  Uint8List someData() => Uint8List.fromList(const [1, 2, 3]);

  group("HaloBleCompanion.onNewHaloBleDevice", () {
    test("listens to every characteristic the device notifies over", () async {
      await aDeviceOfTheCompanion();

      expect(
        ble.subscribed.map((uuid) => uuid.toString()),
        halo.notifiableHaloCharacteristics.map((char) => char.uuid),
      );
    });

    test("listens to nothing of the characteristics which are only exchange zones", () async {
      await aDeviceOfTheCompanion();

      expect(ble.subscribed.map((uuid) => uuid.toString()), isNot(contains(halo.charCAttrTmp.uuid)));
    });

    test("listens to nothing when there is no device any more", () async {
      await companion.onNewHaloBleDevice(null);

      expect(ble.subscribed, isEmpty);
    });

    test("stops listening to the device when it is given up", () async {
      await aDeviceOfTheCompanion();

      await companion.onDisconnection();

      expect(
        ble.unsubscribed.length,
        halo.notifiableHaloCharacteristics.length,
      );
    });

    test("stops listening to a device which disconnects by itself", () async {
      final device = await aDeviceOfTheCompanion();

      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      );
      await pumpHalo();

      expect(await companion.onlyWrite(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
      ), HaloErrorType.commError);
    });
  });

  group("HaloBleCompanion.onlyWrite", () {
    test("writes what it is asked into the characteristic it is asked", () async {
      await aDeviceOfTheCompanion();

      final result = await companion.onlyWrite(
        toWriteInto: halo.charKRequestToDeviceTmp,
        dataToWrite: someData(),
      );

      expect(result, HaloErrorType.noError);
      expect(ble.written.single.characteristic.toString(), halo.charKRequestToDeviceTmp.uuid);
      expect(ble.written.single.value, const [1, 2, 3]);
    });

    test("writes nothing while there is no device to write to", () async {
      final result = await companion.onlyWrite(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
      );

      expect(result, HaloErrorType.commError);
      expect(ble.written, isEmpty);
    });

    test("says that the device could not be written to", () async {
      await aDeviceOfTheCompanion();
      ble.error = Exception("the device is gone");

      final result = await companion.onlyWrite(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
      );

      expect(result, HaloErrorType.commError);
    });
  });

  group("HaloBleCompanion.writeAndWaitNotifResult", () {
    test("answers what the device notified after the writing", () async {
      await aDeviceOfTheCompanion();

      final answer = companion.writeAndWaitNotifResult(
        toWriteInto: halo.charKRequestToDeviceTmp,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
      );
      await pumpHalo();
      await theDeviceNotifies(const [4, 5]);

      final (error, data) = await answer;

      expect(error, HaloErrorType.noError);
      expect(data, const [4, 5]);
    });

    test("writes nothing while there is no device to write to", () async {
      final (error, data) = await companion.writeAndWaitNotifResult(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
      );

      expect(error, HaloErrorType.commError);
      expect(data, isNull);
    });

    test("waits for nothing of a characteristic the application does not listen to", () async {
      await aDeviceOfTheCompanion();
      await halo.charJRequestToDeviceCmd.cleanStream();

      final (error, _) = await companion.writeAndWaitNotifResult(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
      );

      expect(error, HaloErrorType.genericError);
      expect(ble.written, isEmpty);
    });

    test("waits for nothing of a device which could not be written to", () async {
      await aDeviceOfTheCompanion();
      ble.error = Exception("the device is gone");

      final (error, _) = await companion.writeAndWaitNotifResult(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
      );

      expect(error, HaloErrorType.commError);
    });

    test("gives up on a device which notifies nothing", () async {
      await aDeviceOfTheCompanion();

      final (error, data) = await companion.writeAndWaitNotifResult(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
        timeout: aShortTimeout,
      );

      expect(error, HaloErrorType.genericError);
      expect(data, isNull);
    });

    test("gives up when the device is lost while it is waited for", () async {
      final device = await aDeviceOfTheCompanion();

      final answer = companion.writeAndWaitNotifResult(
        toWriteInto: halo.charJRequestToDeviceCmd,
        dataToWrite: someData(),
        toWaitNotifyFrom: halo.charJRequestToDeviceCmd,
      );
      await pumpHalo();
      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      );

      final (error, data) = await answer;

      expect(error, HaloErrorType.genericError);
      expect(data, isNull);
    });
  });
}
