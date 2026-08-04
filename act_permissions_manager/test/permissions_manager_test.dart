// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'fakes/fake_permissions.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeAppLifeCycleManager lifeCycle;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager.android(version: 34))
      ..registerSingleton<AppLifeCycleManager>(lifeCycle);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await lifeCycle.close();
    await globalManager.reset();
  });

  group("PermissionsBuilder", () {
    test("depends on the logger, on the life cycle and on the platform", () {
      expect(PermissionsBuilder().dependsOn(), [
        LoggerManager,
        AppLifeCycleManager,
        PlatformManager,
      ]);
    });
  });

  group("PermissionsManager.getPermission", () {
    test("answers that a permission the device granted is granted", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;

      final status = await PermissionsManager().getPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.granted);
    });

    test("answers that a permission the device refused is denied", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;

      final status = await PermissionsManager().getPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.denied);
    });

    test("answers that an element which asks for nothing is granted", () async {
      expect(await PermissionsManager().getPermission(PermissionElement.wifi),
          PermissionStatus.granted);
    });

    test("answers the worst status of the permissions an element asks for", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.granted;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.denied;

      expect(await PermissionsManager().getPermission(PermissionElement.ble),
          PermissionStatus.denied);
    });

    test("answers that a permission which is refused for good is refused for good", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.denied;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.permanentlyDenied;

      expect(await PermissionsManager().getPermission(PermissionElement.ble),
          PermissionStatus.permanentlyDenied);
    });

    test("prefers a restriction of the device over a refusal of the user", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.denied;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.restricted;

      expect(await PermissionsManager().getPermission(PermissionElement.ble),
          PermissionStatus.restricted);
    });

    test("prefers a refusal of the user over a permission which is limited", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.limited;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.denied;

      expect(await PermissionsManager().getPermission(PermissionElement.ble),
          PermissionStatus.denied);
    });

    test("prefers a permission which is limited over one which is granted", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.granted;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.limited;

      expect(await PermissionsManager().getPermission(PermissionElement.ble),
          PermissionStatus.limited);
    });

    test("stops reading the permissions once one is refused for good", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.permanentlyDenied;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.granted;
      final manager = PermissionsManager();

      await manager.getPermission(PermissionElement.ble);

      expect(await manager.getPermission(PermissionElement.ble),
          PermissionStatus.permanentlyDenied);
    });
  });

  group("PermissionsManager.isGranted", () {
    test("says that an element every permission of which is granted is granted", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.granted;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.granted;

      expect(await PermissionsManager().isGranted(PermissionElement.ble), isTrue);
    });

    test("says that an element which is only limited is not granted", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.limited;

      expect(
        await PermissionsManager().isGranted(PermissionElement.locationWhenInUse),
        isFalse,
      );
    });
  });

  group("PermissionsManager.shouldShowRationale", () {
    test("says that a permission the user already refused has to be explained", () async {
      permissions.rationales.add(Permission.locationWhenInUse);

      expect(
        await PermissionsManager().shouldShowRationale(PermissionElement.locationWhenInUse),
        isTrue,
      );
    });

    test("says that a permission the user never refused needs no explanation", () async {
      expect(
        await PermissionsManager().shouldShowRationale(PermissionElement.locationWhenInUse),
        isFalse,
      );
    });

    test("explains an element as soon as one of its permissions has to be", () async {
      permissions.rationales.add(Permission.bluetoothConnect);

      expect(await PermissionsManager().shouldShowRationale(PermissionElement.ble), isTrue);
    });
  });

  group("PermissionsManager.requestPermission", () {
    test("asks the user for a permission which was refused", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;

      final status = await PermissionsManager().requestPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.granted);
      expect(permissions.requested, [Permission.locationWhenInUse]);
    });

    test("asks the user for nothing when the permission is already granted", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.granted;

      final status = await PermissionsManager().requestPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.granted);
      expect(permissions.requested, isEmpty);
    });

    test("asks the user for nothing when the permission was refused for good", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.permanentlyDenied;

      final status = await PermissionsManager().requestPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.permanentlyDenied);
      expect(permissions.requested, isEmpty);
    });

    test("asks the user for every permission of the element", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.denied;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.denied;

      await PermissionsManager().requestPermission(PermissionElement.ble);

      expect(permissions.requested, [Permission.bluetoothScan, Permission.bluetoothConnect]);
    });

    test("stops asking as soon as the user refuses one permission", () async {
      permissions.statuses[Permission.bluetoothScan] = PermissionStatus.denied;
      permissions.answersToRequest[Permission.bluetoothScan] = PermissionStatus.permanentlyDenied;
      permissions.statuses[Permission.bluetoothConnect] = PermissionStatus.denied;

      final status = await PermissionsManager().requestPermission(PermissionElement.ble);

      expect(status, PermissionStatus.permanentlyDenied);
      expect(permissions.requested, [Permission.bluetoothScan]);
    });

    test("says that a permission is refused for good when the user was already asked", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;
      permissions.answersToRequest[Permission.locationWhenInUse] = PermissionStatus.denied;
      permissions.rationales.add(Permission.locationWhenInUse);

      final status = await PermissionsManager().requestPermission(
        PermissionElement.locationWhenInUse,
        checkRationale: true,
      );

      expect(status, PermissionStatus.permanentlyDenied);
    });

    test("leaves a permission the user refuses denied when it explains nothing", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;
      permissions.answersToRequest[Permission.locationWhenInUse] = PermissionStatus.denied;
      permissions.rationales.add(Permission.locationWhenInUse);

      final status = await PermissionsManager().requestPermission(
        PermissionElement.locationWhenInUse,
      );

      expect(status, PermissionStatus.denied);
    });

    test("tells the watcher of the element which status it ended on", () async {
      permissions.statuses[Permission.locationWhenInUse] = PermissionStatus.denied;
      final manager = PermissionsManager();
      final handler = manager.getAHandler(PermissionElement.locationWhenInUse);
      addTearDown(handler.close);

      await manager.requestPermission(PermissionElement.locationWhenInUse);

      expect(await handler.currentStatus, PermissionStatus.granted);
    });
  });

  group("PermissionsManager.getAHandler", () {
    test("hands over a handler of the element which is asked for", () async {
      final handler = PermissionsManager().getAHandler(PermissionElement.ble);
      addTearDown(handler.close);

      expect(handler.permissionElement, PermissionElement.ble);
    });

    test("hands over another handler of the same element", () async {
      final manager = PermissionsManager();
      final first = manager.getAHandler(PermissionElement.ble);
      addTearDown(first.close);

      final second = manager.getAHandler(PermissionElement.ble);
      addTearDown(second.close);

      expect(second, isNot(same(first)));
    });
  });
}
