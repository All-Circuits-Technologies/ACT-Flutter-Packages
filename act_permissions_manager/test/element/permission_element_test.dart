// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element_extension.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../fakes/fake_permissions.dart';

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// Says that the application runs on [platform].
  void runningOn(FakePlatformManager platform) =>
      globalGetIt().registerSingleton<PlatformManager>(platform);

  group("PermissionElementExtension.permissions", () {
    test("answers the permission of the device an element stands for", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElement.locationWhenInUse.permissions, [Permission.locationWhenInUse]);
    });
  });

  group("PermissionElementHelper.getPermissions", () {
    test("asks Android to be left running in the background", () {
      runningOn(FakePlatformManager.android(version: 34));

      expect(PermissionElementHelper.getPermissions(PermissionElement.background), [
        Permission.ignoreBatteryOptimizations,
      ]);
    });

    test("asks nothing of a device which is not Android to run in the background", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElementHelper.getPermissions(PermissionElement.background), isEmpty);
    });

    test("asks a recent Android for the Bluetooth permissions of its own", () {
      runningOn(FakePlatformManager.android(version: 34));

      expect(PermissionElementHelper.getPermissions(PermissionElement.ble), [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ]);
    });

    test("asks an older Android for the location to scan the Bluetooth", () {
      runningOn(FakePlatformManager.android(version: 30));

      expect(PermissionElementHelper.getPermissions(PermissionElement.ble), [
        Permission.locationWhenInUse,
        Permission.bluetooth,
      ]);
    });

    test("asks a recent Android whose version is unknown for the permissions of its own", () {
      runningOn(FakePlatformManager.android());

      expect(PermissionElementHelper.getPermissions(PermissionElement.ble), [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ]);
    });

    test("asks iOS for the Bluetooth itself", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElementHelper.getPermissions(PermissionElement.ble), [
        Permission.bluetooth,
      ]);
    });

    test("asks nothing of a device which is neither Android nor iOS for the Bluetooth", () {
      runningOn(FakePlatformManager());

      expect(PermissionElementHelper.getPermissions(PermissionElement.ble), isEmpty);
    });

    test("asks for the location however the device is", () {
      runningOn(FakePlatformManager());

      expect(PermissionElementHelper.getPermissions(PermissionElement.locationAlways), [
        Permission.locationAlways,
      ]);
      expect(PermissionElementHelper.getPermissions(PermissionElement.locationWhenInUse), [
        Permission.locationWhenInUse,
      ]);
    });

    test("asks iOS for the tracking of the user", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElementHelper.getPermissions(PermissionElement.trackingAuthorization), [
        Permission.appTrackingTransparency,
      ]);
    });

    test("asks nothing of a device which is not iOS for the tracking of the user", () {
      runningOn(FakePlatformManager.android(version: 34));

      expect(
        PermissionElementHelper.getPermissions(PermissionElement.trackingAuthorization),
        isEmpty,
      );
    });

    test("asks nothing for the WiFi, whatever the device", () {
      runningOn(FakePlatformManager.android(version: 34));

      expect(PermissionElementHelper.getPermissions(PermissionElement.wifi), isEmpty);
    });
  });

  group("PermissionElement.isAskingLocation", () {
    test("says that an element which asks for the location asks for it", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElement.locationWhenInUse.isAskingLocation, isTrue);
      expect(PermissionElement.locationAlways.isAskingLocation, isTrue);
    });

    test("says that the Bluetooth of an older Android asks for the location", () {
      runningOn(FakePlatformManager.android(version: 30));

      expect(PermissionElement.ble.isAskingLocation, isTrue);
    });

    test("says that the Bluetooth of a recent Android does not ask for the location", () {
      runningOn(FakePlatformManager.android(version: 34));

      expect(PermissionElement.ble.isAskingLocation, isFalse);
    });

    test("says that an element which asks nothing does not ask for the location", () {
      runningOn(FakePlatformManager.ios());

      expect(PermissionElement.wifi.isAskingLocation, isFalse);
    });
  });
}
