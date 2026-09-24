// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager/src/data/constants.dart' as ble_constants;
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ble.dart';

/// The step the clock of a test is moved by.
const _aStep = Duration(milliseconds: 250);

/// The time which is let pass around what a test waits for, so that it is waited for rather than
/// measured to the millisecond.
const _aMargin = Duration(milliseconds: 500);

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

  /// A device of the application which was scanned and which answers its services.
  BleDevice aDevice() {
    ble.services = [aDiscoveredService()];

    return BleDevice(BleScannedDevice(aDiscoveredDevice()));
  }

  /// Moves the clock of the application by [duration], one step at a time.
  ///
  /// The package waits for the streams of the plugin to be closed, and those answer on the event
  /// queue of the test rather than on the clock [fake] moves: the two are stepped through
  /// together, otherwise the connection stalls while the clock runs away from it.
  Future<void> letTimePass(FakeAsync fake, Duration duration) async {
    for (var left = duration; left > Duration.zero; left -= _aStep) {
      await pumpEventQueue(times: 3);
      fake.elapse(left < _aStep ? left : _aStep);
    }

    await pumpEventQueue(times: 3);
  }

  /// Leaves the connection which is running to its end and forgets [device].
  ///
  /// Nothing may be left running at the end of a test, otherwise the connection keeps the mutex
  /// of the manager and the disposing of the manager waits for it forever.
  Future<void> endTheConnection(FakeAsync fake, BleDevice device) async {
    await letTimePass(fake, ble_constants.connectTimeout * 3);
    fake.run((_) => unawaited(device.dispose()));
    await letTimePass(fake, _aMargin);
  }

  /// Asks the manager to connect to a device and lets the first attempt start.
  ///
  /// The device and what the connection answered are given back, the answers being empty for as
  /// long as the connection is running. The connection is left to its end when the test is over,
  /// whatever the test made of it.
  Future<(BleDevice, List<bool>)> startConnecting(FakeAsync fake) async {
    late BleDevice device;
    final answers = <bool>[];

    fake.run((_) {
      device = aDevice();
      unawaited(manager.bleGattService.connect(device).then(answers.add));
    });
    addTearDown(() => endTheConnection(fake, device));
    await letTimePass(fake, _aMargin);

    return (device, answers);
  }

  /// Tells the application that the attempt which is running failed the way Android does when it
  /// answers a GATT_ERROR 133: the device connects and is disconnected at once.
  Future<void> failTheAttempt(FakeAsync fake) async {
    fake.run((_) => unawaited(ble.tellConnection(DeviceConnectionState.connecting)));
    await letTimePass(fake, _aMargin);
    fake.run((_) => unawaited(ble.tellConnection(DeviceConnectionState.disconnected)));
    await letTimePass(fake, _aMargin);
  }

  group("BleGattService.connect", () {
    test("tries again a short pause after an attempt which failed", () async {
      final fake = FakeAsync();
      await startConnecting(fake);

      expect(ble.connected, [aDeviceId]);

      await failTheAttempt(fake);
      await letTimePass(fake, ble_constants.lowLevelConnectRetryDelay - _aMargin);

      expect(ble.connected, [aDeviceId]);

      await letTimePass(fake, _aMargin * 2);

      expect(ble.connected, [aDeviceId, aDeviceId]);
    });

    test("connects to a device which answers on the second attempt", () async {
      final fake = FakeAsync();
      final (device, answers) = await startConnecting(fake);

      await failTheAttempt(fake);
      await letTimePass(fake, ble_constants.lowLevelConnectRetryDelay + _aMargin);

      expect(ble.connected.length, 2);

      fake.run((_) => unawaited(ble.tellConnection(DeviceConnectionState.connected)));
      await letTimePass(fake, _aMargin);

      expect(answers, [true]);
      expect(device.connectionState, DeviceConnectionState.connected);
    });

    test("gives up once the whole time of a connection was spent", () async {
      final fake = FakeAsync();
      final (_, answers) = await startConnecting(fake);

      // The device answers nothing at all, so every attempt is left to its own timeout: the last
      // one which starts inside the time of a connection is the one which ends after it.
      await letTimePass(
        fake,
        ble_constants.connectTimeout +
            ble_constants.lowLevelConnectTimeout +
            ble_constants.lowLevelConnectRetryDelay,
      );

      expect(answers, [false]);
      expect(ble.connected.length, 2);
    });
  });
}
