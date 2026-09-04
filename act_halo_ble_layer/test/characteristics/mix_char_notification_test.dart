// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_ble_platform_interface/reactive_ble_platform_interface.dart';

import '../fakes/fake_halo_ble.dart';

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
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The characteristic of the device the application listens to.
  ///
  /// Nothing is listened to when [subscribed] says so.
  Future<MixCharNotification> aCharacteristic({
    bool subscribed = true,
    BleDevice? device,
  }) async {
    final characteristic = halo.charJRequestToDeviceCmd;

    if (subscribed) {
      final bleDevice = device ?? await aHaloDevice();
      final (_, stream) = await manager.bleGattService.subscribeBleNotification(
        bleDevice,
        characteristic.uuid,
      );
      await characteristic.onStreamUpdate(stream!, bleDevice.connectionStateStream);
      await pumpHalo();
    }

    addTearDown(characteristic.cleanStream);

    return characteristic;
  }

  /// Tells the application that the characteristic of the device answered [value].
  Future<void> theDeviceNotifies(List<int> value) =>
      ble.tellNotification(halo.charJRequestToDeviceCmd.uuid, value);

  group("MixCharNotification.prepareWaitResponse", () {
    test("waits for nothing of a characteristic nothing listens to", () async {
      final characteristic = await aCharacteristic(subscribed: false);

      expect(await characteristic.prepareWaitResponse(), isNull);
    });

    test("waits for the device once the application listens to it", () async {
      final characteristic = await aCharacteristic();

      expect(await characteristic.prepareWaitResponse(), isNotNull);
    });
  });

  group("ResponseWaiter.waitResponse", () {
    test("answers the value the device notified", () async {
      final characteristic = await aCharacteristic();
      final waiter = await characteristic.prepareWaitResponse();

      final answer = waiter!.waitResponse();
      await theDeviceNotifies(const [1, 2, 3]);

      expect(await answer, const [1, 2, 3]);
    });

    test("answers every waiter of the characteristic with the same value", () async {
      final characteristic = await aCharacteristic();
      final first = await characteristic.prepareWaitResponse();
      final second = await characteristic.prepareWaitResponse();

      final answers = Future.wait([first!.waitResponse(), second!.waitResponse()]);
      await theDeviceNotifies(const [1]);

      expect(await answers, const [
        [1],
        [1],
      ]);
    });

    test("answers nothing of a value which was notified before the waiting", () async {
      final characteristic = await aCharacteristic();
      await theDeviceNotifies(const [1, 2, 3]);
      final waiter = await characteristic.prepareWaitResponse();

      expect(await waiter!.waitResponse(timeout: aShortTimeout), isNull);
    });

    test("gives up on a device which answers nothing", () async {
      final characteristic = await aCharacteristic();
      final waiter = await characteristic.prepareWaitResponse();

      expect(await waiter!.waitResponse(timeout: aShortTimeout), isNull);
    });

    test("waits for a device as long as it is asked to", () async {
      final characteristic = await aCharacteristic();
      final waiter = await characteristic.prepareWaitResponse();
      var answered = false;

      final answer = waiter!.waitResponse(timeout: null);
      unawaited(answer.then((_) => answered = true));
      await Future.delayed(const Duration(milliseconds: 30));

      expect(answered, isFalse);

      await theDeviceNotifies(const [1]);

      expect(await answer, const [1]);
    });

    test("gives up on a device which is disconnecting", () async {
      final device = await aHaloDevice();
      final characteristic = await aCharacteristic(device: device);
      final waiter = await characteristic.prepareWaitResponse();

      final answer = waiter!.waitResponse();
      await device.setConnectionStream(
        Stream.value(
          const ConnectionStateUpdate(
            deviceId: aDeviceId,
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      );

      expect(await answer, isNull);
    });

    test("gives up when the application stops listening to the characteristic", () async {
      final characteristic = await aCharacteristic();
      final waiter = await characteristic.prepareWaitResponse();

      final answer = waiter!.waitResponse();
      await characteristic.cleanStream();

      expect(await answer, isNull);
    });

    test("answers nothing to a waiting which was given up", () async {
      final characteristic = await aCharacteristic();
      final waiter = await characteristic.prepareWaitResponse();

      final answer = waiter!.waitResponse();
      await waiter.cancel();

      expect(await answer, isNull);
    });

    test("says nothing to the other waiters when one of them is given up", () async {
      final characteristic = await aCharacteristic();
      final given = await characteristic.prepareWaitResponse();
      final kept = await characteristic.prepareWaitResponse();

      final answer = kept!.waitResponse();
      await given!.cancel();
      await theDeviceNotifies(const [1]);

      expect(await answer, const [1]);
    });
  });

  group("MixCharNotification.cleanStream", () {
    test("waits for nothing of a characteristic it no longer listens to", () async {
      final characteristic = await aCharacteristic();

      await characteristic.cleanStream();

      expect(await characteristic.prepareWaitResponse(), isNull);
    });

    test("listens to nothing twice when the application listens again", () async {
      final device = await aHaloDevice();
      final characteristic = await aCharacteristic(device: device);
      final waiter = await characteristic.prepareWaitResponse();

      final answer = waiter!.waitResponse();
      final (_, stream) = await manager.bleGattService.subscribeBleNotification(
        device,
        characteristic.uuid,
      );
      await characteristic.onStreamUpdate(stream!, device.connectionStateStream);

      expect(await answer, isNull);
    });
  });
}
