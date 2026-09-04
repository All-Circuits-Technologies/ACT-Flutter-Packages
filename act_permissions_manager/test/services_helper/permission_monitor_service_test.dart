// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
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
  late FakePermViewBuilder views;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    views = FakePermViewBuilder(
      answers: {
        PermissionViewAction.askPermission: FakePermViewBuilder.theUserAnswers(),
        PermissionViewAction.informPermanentlyDenied: FakePermViewBuilder.theUserAnswers(),
      },
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager.android(version: 34))
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<FakePermRouterManager>(FakePermRouterManager());

    final contextualViews = ContextualViewsBuilder<FakePermRouterManager>(
      viewBuilder: views,
    ).factory();
    await contextualViews.initLifeCycle();
    globalGetIt().registerSingleton<ContextualViewsManager>(contextualViews);
    addTearDown(contextualViews.disposeLifeCycle);

    manager = PermissionsManager();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The monitor of the element the tests watch, closed once the test is over.
  PermissionMonitorService aMonitor() {
    final monitor = PermissionMonitorService.monitorService(
      permissionsManager: manager,
      permissionElement: _anElement,
    );
    addTearDown(monitor.close);

    return monitor;
  }

  group("PermissionMonitorService.verifyBeforeAction", () {
    test("says that a permission which is granted is granted", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;

      expect(await aMonitor().verifyBeforeAction(), isTrue);
    });

    test("says that a permission which is refused is not granted", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;

      expect(await aMonitor().verifyBeforeAction(), isFalse);
    });

    test("asks the user for nothing", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;

      await aMonitor().verifyBeforeAction();

      expect(permissions.requested, isEmpty);
      expect(views.displayed, isEmpty);
    });
  });

  group("PermissionMonitorService.verifyAndAskBeforeAction", () {
    test("asks the user for nothing when the permission is already granted", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;

      expect(await aMonitor().verifyAndAskBeforeAction(), isTrue);
      expect(views.displayed, isEmpty);
    });

    test("explains why the permission is needed before it asks for it", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isTrue);
      expect(views.displayed, [PermissionViewAction.askPermission]);
      expect(permissions.requested, [_aPermission]);
    });

    test("asks for the permission without explaining when it is told not to", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;

      final granted = await aMonitor().verifyAndAskBeforeAction(
        displayContextualIfNeeded: false,
      );

      expect(granted, isTrue);
      expect(views.displayed, isEmpty);
      expect(permissions.requested, [_aPermission]);
    });

    test("asks for nothing when the user leaves the page which explains why", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      views.answers[PermissionViewAction.askPermission] = FakePermViewBuilder.theUserLeaves();

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isFalse);
      expect(permissions.requested, isEmpty);
    });

    test("tells the user that the permission was refused for good", () async {
      permissions.statuses[_aPermission] = PermissionStatus.permanentlyDenied;
      permissions.settingsAnswer = {_aPermission: PermissionStatus.granted};

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isTrue);
      expect(views.displayed, [PermissionViewAction.informPermanentlyDenied]);
      expect(permissions.settingsCount, 1);
    });

    test("leaves the settings alone when the user leaves the page which tells", () async {
      permissions.statuses[_aPermission] = PermissionStatus.permanentlyDenied;
      views.answers[PermissionViewAction.informPermanentlyDenied] =
          FakePermViewBuilder.theUserLeaves();

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isFalse);
      expect(permissions.settingsCount, 0);
    });

    test("opens the settings itself when it is told to explain nothing", () async {
      permissions.statuses[_aPermission] = PermissionStatus.permanentlyDenied;
      permissions.settingsAnswer = {_aPermission: PermissionStatus.granted};

      final granted = await aMonitor().verifyAndAskBeforeAction(
        displayContextualIfNeeded: false,
      );

      expect(granted, isTrue);
      expect(views.displayed, isEmpty);
      expect(permissions.settingsCount, 1);
    });

    test("tells the user that a permission the device restricts cannot be granted", () async {
      permissions.statuses[_aPermission] = PermissionStatus.restricted;
      views.answers[PermissionViewAction.informPermanentlyDenied] =
          FakePermViewBuilder.theUserLeaves();

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isFalse);
      expect(views.displayed, [PermissionViewAction.informPermanentlyDenied]);
    });

    test("reads a permission the user already refused as refused for good", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      permissions.rationales.add(_aPermission);
      views.answers[PermissionViewAction.informPermanentlyDenied] =
          FakePermViewBuilder.theUserLeaves();

      final granted = await aMonitor().verifyAndAskBeforeAction(checkRationale: true);

      expect(granted, isFalse);
      expect(views.displayed, [PermissionViewAction.informPermanentlyDenied]);
      expect(permissions.requested, isEmpty);
    });

    test("asks once and stops when the user refuses the permission for good", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      permissions.answersToRequest[_aPermission] = PermissionStatus.permanentlyDenied;

      final granted = await aMonitor().verifyAndAskBeforeAction();

      expect(granted, isFalse);
      expect(views.displayed, [PermissionViewAction.askPermission]);
      expect(permissions.requested, [_aPermission]);
    });

    test("leaves the settings alone when the user just refused the permission", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      permissions.answersToRequest[_aPermission] = PermissionStatus.permanentlyDenied;

      final granted = await aMonitor().verifyAndAskBeforeAction(
        displayContextualIfNeeded: false,
      );

      expect(granted, isFalse);
      expect(permissions.settingsCount, 0);
    });
  });

  group("PermissionMonitorService.hasPermissionStream", () {
    test("tells the application when the permission is granted", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      final monitor = aMonitor();
      await monitor.verifyBeforeAction();
      final granted = <bool>[];
      monitor.hasPermissionStream.listen(granted.add);

      await monitor.verifyAndAskBeforeAction();
      await pumpEventQueue();

      expect(granted, [true]);
    });

    test("says nothing when a permission which was refused is refused for good", () async {
      permissions.statuses[_aPermission] = PermissionStatus.denied;
      permissions.answersToRequest[_aPermission] = PermissionStatus.permanentlyDenied;
      final monitor = aMonitor();
      await monitor.verifyBeforeAction();
      final granted = <bool>[];
      monitor.hasPermissionStream.listen(granted.add);

      await monitor.verifyAndAskBeforeAction();
      await pumpEventQueue();

      expect(granted, isEmpty);
    });
  });

  group("PermissionMonitorService.close", () {
    test("stops telling the application about the permission", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final monitor = PermissionMonitorService.monitorService(
        permissionsManager: manager,
        permissionElement: _anElement,
      );
      var closed = false;
      monitor.hasPermissionStream.listen(null, onDone: () => closed = true);

      await monitor.close();
      await pumpEventQueue();

      expect(closed, isTrue);
    });
  });
}
