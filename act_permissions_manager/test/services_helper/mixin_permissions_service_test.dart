// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../fakes/fake_permissions.dart';

/// The permission of the device the location asks for.
const _aLocation = Permission.locationWhenInUse;

/// The permissions of the device the Bluetooth of a recent Android asks for.
const _aBluetooth = [Permission.bluetoothScan, Permission.bluetoothConnect];

void main() {
  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeAppLifeCycleManager lifeCycle;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager.android(version: 34))
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// Says that the device granted every [granted] permission and refused the others.
  void deviceGranted(List<Permission> granted) {
    for (final permission in granted) {
      permissions.statuses[permission] = PermissionStatus.granted;
    }
  }

  /// The service of an application which needs [configs], initialized.
  Future<FakePermissionsService> aService(List<PermissionConfig> configs) async {
    final service = FakePermissionsService(configs);
    await service.initLifeCycle();
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("MPermissionsServiceBuilder", () {
    test("depends on the manager of the permissions", () {
      final builder = FakePermissionsServiceBuilder(() => FakePermissionsService(const []));

      expect(builder.dependsOn(), [PermissionsManager]);
    });
  });

  group("MPermissionsService.initLifeCycle", () {
    test("raises when a permission depends on one the service does not need", () async {
      final service = FakePermissionsService(const [
        PermissionConfig(
          element: PermissionElement.ble,
          whenAskingDependsOn: [PermissionElement.locationWhenInUse],
        ),
      ]);
      addTearDown(service.disposeLifeCycle);

      expect(service.initLifeCycle, throwsA(isA<NotKnownDependencyException>()));
    });

    test("says that a service which needs nothing has everything it needs", () async {
      final service = await aService(const []);

      expect(service.hasPermissions, isTrue);
    });

    test("says that a service which needs a permission has nothing yet", () async {
      deviceGranted([_aLocation]);

      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);

      expect(service.hasPermissions, isFalse);
    });
  });

  group("MPermissionsService.checkPermissions", () {
    test("answers that a permission the device granted is granted", () async {
      deviceGranted([_aLocation]);
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);

      final granted = await service.checkPermissions(displayContextualIfNeeded: false);

      expect(granted, isTrue);
      expect(service.hasPermissions, isTrue);
    });

    test("asks nothing of the user when it is told not to", () async {
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);

      final granted = await service.checkPermissions(askActionToUser: false);

      expect(granted, isFalse);
      expect(permissions.requested, isEmpty);
    });

    test("answers what it already knows when it asks nothing of the user", () async {
      deviceGranted([_aLocation]);
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);
      await service.checkPermissions(displayContextualIfNeeded: false);

      expect(await service.checkPermissions(askActionToUser: false), isTrue);
    });
  });

  group("MPermissionsService.checkAndAskPermissions", () {
    test("asks the user for every permission the service needs", () async {
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
        PermissionConfig(element: PermissionElement.ble),
      ]);

      final granted = await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(granted, isTrue);
      expect(permissions.requested, [_aLocation, ..._aBluetooth]);
    });

    test("asks for a permission after the one it depends on", () async {
      final service = await aService(const [
        PermissionConfig(
          element: PermissionElement.ble,
          whenAskingDependsOn: [PermissionElement.locationWhenInUse],
        ),
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);

      await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(permissions.requested, [_aLocation, ..._aBluetooth]);
    });

    test("asks for nothing which depends on a permission the user refused", () async {
      permissions.answersToRequest[_aLocation] = PermissionStatus.denied;
      final service = await aService(const [
        PermissionConfig(
          element: PermissionElement.ble,
          whenAskingDependsOn: [PermissionElement.locationWhenInUse],
        ),
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);

      final granted = await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(granted, isFalse);
      expect(permissions.requested, contains(_aLocation));
      expect(permissions.requested, isNot(contains(Permission.bluetoothScan)));
    });

    test("asks for every permission even when one of them is refused", () async {
      permissions.answersToRequest[_aLocation] = PermissionStatus.denied;
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
        PermissionConfig(element: PermissionElement.ble),
      ]);

      final granted = await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(granted, isFalse);
      expect(permissions.requested, containsAll(_aBluetooth));
    });

    test("asks for nothing more once a permission is granted", () async {
      deviceGranted([_aLocation]);
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);
      await service.checkAndAskPermissions(displayContextualIfNeeded: false);
      final reads = permissions.checked.length;

      await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(permissions.checked.length, reads);
    });
  });

  group("MPermissionsService.permissionsStream", () {
    test("tells the application when the service has everything it needs", () async {
      deviceGranted([_aLocation]);
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);
      final granted = <bool>[];
      service.permissionsStream.listen(granted.add);

      await service.checkAndAskPermissions(displayContextualIfNeeded: false);
      await pumpEventQueue();

      expect(granted, [true]);
    });

    test("says nothing while a permission the service needs is missing", () async {
      deviceGranted([Permission.bluetoothScan, Permission.bluetoothConnect]);
      permissions.answersToRequest[_aLocation] = PermissionStatus.denied;
      final service = await aService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
        PermissionConfig(element: PermissionElement.ble),
      ]);
      final granted = <bool>[];
      service.permissionsStream.listen(granted.add);

      await service.checkAndAskPermissions(displayContextualIfNeeded: false);
      await pumpEventQueue();

      expect(granted, isEmpty);
    });
  });

  group("MPermissionsService.disposeLifeCycle", () {
    test("stops telling the application about its permissions", () async {
      final service = FakePermissionsService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);
      await service.initLifeCycle();
      var closed = false;
      service.permissionsStream.listen(null, onDone: () => closed = true);

      await service.disposeLifeCycle();
      await pumpEventQueue();

      expect(closed, isTrue);
    });

    test("stops reading the permissions it needed", () async {
      deviceGranted([_aLocation]);
      final service = FakePermissionsService(const [
        PermissionConfig(element: PermissionElement.locationWhenInUse),
      ]);
      await service.initLifeCycle();
      await service.checkAndAskPermissions(displayContextualIfNeeded: false);

      await service.disposeLifeCycle();
      final reads = permissions.checked.length;
      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(permissions.checked.length, reads);
    });
  });
}
