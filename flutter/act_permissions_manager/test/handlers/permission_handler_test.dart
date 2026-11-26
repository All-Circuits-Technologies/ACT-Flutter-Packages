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

/// The element the tests watch, which asks for one permission of the device.
const _anElement = PermissionElement.locationWhenInUse;

/// The permission of the device the watched element asks for.
const _aPermission = Permission.locationWhenInUse;

void main() {
  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeAppLifeCycleManager lifeCycle;
  late PermissionsManager manager;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager.android(version: 34))
      ..registerSingleton<AppLifeCycleManager>(lifeCycle);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    manager = PermissionsManager();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// A handler of the element the tests watch, closed once the test is over.
  PermissionHandler aHandler() {
    final handler = manager.getAHandler(_anElement);
    addTearDown(handler.close);

    return handler;
  }

  group("PermissionHandler.permissionElement", () {
    test("says which element it watches", () {
      expect(aHandler().permissionElement, _anElement);
    });
  });

  group("PermissionHandler.currentStatus", () {
    test("answers the status of the permission of the device", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;

      expect(await aHandler().currentStatus, PermissionStatus.granted);
    });

    test("answers the status it already read rather than reading it again", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final handler = aHandler();
      await handler.currentStatus;

      permissions.statuses[_aPermission] = PermissionStatus.denied;

      expect(await handler.currentStatus, PermissionStatus.granted);
    });
  });

  group("PermissionHandler.statusStream", () {
    test("tells the application when the status of the permission changed", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      final handler = aHandler();
      await handler.currentStatus;
      final statuses = <PermissionStatus>[];
      handler.statusStream.listen(statuses.add);

      await handler.requestPermission();
      await pumpEventQueue();

      expect(statuses, [PermissionStatus.granted]);
    });

    test("says nothing when the status of the permission did not change", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final handler = aHandler();
      await handler.currentStatus;
      final statuses = <PermissionStatus>[];
      handler.statusStream.listen(statuses.add);

      await handler.requestPermission();
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });
  });

  group("PermissionHandler.requestPermission", () {
    test("asks the user for the permission of the element", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;

      final status = await aHandler().requestPermission();

      expect(status, PermissionStatus.granted);
      expect(permissions.requested, [_aPermission]);
    });
  });

  group("PermissionHandler.shouldShowRationale", () {
    test("says whether the user was already asked for the permission", () async {
      permissions.rationales.add(_aPermission);

      expect(await aHandler().shouldShowRationale(), isTrue);
    });
  });

  group("PermissionHandler.isInsideAppStream", () {
    test("says that the application was left", () async {
      final handler = aHandler();
      await handler.currentStatus;
      final inside = <bool>[];
      handler.isInsideAppStream.listen(inside.add);

      await lifeCycle.goTo(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(inside, [false]);
    });

    test("says that the application came back", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final handler = aHandler();
      await handler.currentStatus;
      final inside = <bool>[];
      handler.isInsideAppStream.listen(inside.add);

      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(inside, [false, true]);
    });

    test("says nothing of a state which neither leaves nor comes back", () async {
      final handler = aHandler();
      await handler.currentStatus;
      final inside = <bool>[];
      handler.isInsideAppStream.listen(inside.add);

      await lifeCycle.goTo(AppLifecycleState.inactive);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(inside, isEmpty);
    });
  });

  group("PermissionWatcher", () {
    test("reads the permission again when the application comes back", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      final handler = aHandler();
      await handler.currentStatus;
      permissions.statuses[_aPermission] = PermissionStatus.granted;

      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(await handler.currentStatus, PermissionStatus.granted);
    });

    test("stops reading the permission once its last handler is closed", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final handler = manager.getAHandler(_anElement);
      await handler.currentStatus;
      await handler.close();
      final reads = permissions.checked.length;

      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(permissions.checked.length, reads);
    });

    test("keeps reading the permission while one handler is left", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final first = manager.getAHandler(_anElement);
      final second = aHandler();
      await second.currentStatus;
      await first.close();
      final reads = permissions.checked.length;

      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(permissions.checked.length, greaterThan(reads));
    });
  });
}
