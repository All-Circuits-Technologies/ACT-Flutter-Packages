// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_abs_peripherals_manager/act_abs_peripherals_manager.dart';
import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// The permission of the device the peripheral of the tests needs.
const _aPermission = Permission.locationWhenInUse;

/// The platform the tests say the application runs on.
class _FakePlatformManager extends PlatformManager {
  @override
  bool get isAndroid => true;

  @override
  int? get version => 34;
}

/// The life cycle of an application under test, which is never left.
class _FakeAppLifeCycleManager extends AppLifeCycleManager {
  final StreamController<AppLifecycleState?> _ctrl =
      StreamController<AppLifecycleState?>.broadcast();

  @override
  Stream<AppLifecycleState?> get lifeCycleStream => _ctrl.stream;

  Future<void> close() => _ctrl.close();
}

/// The permissions of the device, answered by the test.
class _FakePermissionsPlatform extends PermissionHandlerPlatform {
  /// The status of each permission, the ones which are absent being denied.
  final Map<Permission, PermissionStatus> statuses = {};

  /// The status a permission takes once it has been requested.
  PermissionStatus answerToRequest = PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      statuses[permission] ?? PermissionStatus.denied;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      statuses[permission] = answerToRequest;
    }

    return {for (final permission in permissions) permission: answerToRequest};
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;

  @override
  Future<bool> openAppSettings() async => true;
}

/// A manager of a peripheral of an application under test.
class _FakePeriphManager extends AbstractPeriphManager {
  /// Whether the service of the peripheral can be switched on.
  bool enablingWorks;

  /// The number of times the service was asked to switch itself on.
  int askedEnabling = 0;

  /// What the enabling was told about the page which has to stay up.
  bool? enablingWasCompulsory;

  /// Class constructor
  _FakePeriphManager({this.enablingWorks = true});

  /// Tells the application that the service of the peripheral is now switched on.
  void tellEnabled({required bool isEnabled}) => setEnabled(isEnabled);

  @override
  List<PermissionConfig> getPermissionsConfig() => const [
    PermissionConfig(element: PermissionElement.locationWhenInUse),
  ];

  @override
  EnableServiceElement getElement() => EnableServiceElement.location;

  @override
  Future<bool> askForEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  }) async {
    askedEnabling++;
    enablingWasCompulsory = isAcceptanceCompulsory;
    setEnabled(enablingWorks);

    return enablingWorks;
  }
}

/// The builder of a manager of a peripheral of an application under test.
class _FakePeriphBuilder extends AbstractPeriphBuilder<_FakePeriphManager> {
  _FakePeriphBuilder(super.factory);
}

void main() {
  late FakeGlobalManager globalManager;
  late _FakePermissionsPlatform permissions;
  late _FakeAppLifeCycleManager lifeCycle;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = _FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = permissions;
    lifeCycle = _FakeAppLifeCycleManager();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    globalGetIt()
      ..registerSingleton<PlatformManager>(_FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The manager of the peripheral of an application under test, initialized.
  Future<_FakePeriphManager> aManager({bool enablingWorks = true}) async {
    final manager = _FakePeriphManager(enablingWorks: enablingWorks);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("AbstractPeriphBuilder", () {
    test("depends on the manager of the permissions", () {
      final builder = _FakePeriphBuilder(_FakePeriphManager.new);

      expect(builder.dependsOn(), [PermissionsManager]);
    });
  });

  group("AbstractPeriphManager.isFullyEnabled", () {
    test("says that a peripheral which was never asked for is not usable", () async {
      final manager = await aManager();

      expect(manager.isFullyEnabled(), isFalse);
    });

    test("says that a peripheral whose service is off is not usable", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final manager = await aManager();
      await manager.checkAndAskPermissions(displayContextualIfNeeded: false);

      expect(manager.hasPermissions, isTrue);
      expect(manager.isFullyEnabled(), isFalse);
    });

    test("says that a peripheral whose permissions are missing is not usable", () async {
      final manager = await aManager()
        ..tellEnabled(isEnabled: true);

      expect(manager.isEnabled, isTrue);
      expect(manager.isFullyEnabled(), isFalse);
    });

    test("says that a peripheral which has both is usable", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final manager = await aManager();
      await manager.checkAndAskPermissions(displayContextualIfNeeded: false);
      manager.tellEnabled(isEnabled: true);

      expect(manager.isFullyEnabled(), isTrue);
    });
  });

  group("AbstractPeriphManager.checkAndAskForPermissionsAndServices", () {
    test("asks for the permissions and then for the service", () async {
      final manager = await aManager();

      final usable = await manager.checkAndAskForPermissionsAndServices(
        displayContextualIfNeeded: false,
      );

      expect(usable, isTrue);
      expect(manager.hasPermissions, isTrue);
      expect(manager.askedEnabling, 1);
    });

    test("asks nothing of the service when a permission is missing", () async {
      permissions.answerToRequest = PermissionStatus.denied;
      final manager = await aManager();

      final usable = await manager.checkAndAskForPermissionsAndServices(
        displayContextualIfNeeded: false,
      );

      expect(usable, isFalse);
      expect(manager.askedEnabling, 0);
    });

    test("answers that the peripheral is not usable when the service stays off", () async {
      final manager = await aManager(enablingWorks: false);

      final usable = await manager.checkAndAskForPermissionsAndServices(
        displayContextualIfNeeded: false,
      );

      expect(usable, isFalse);
      expect(manager.askedEnabling, 1);
    });

    test("tells the service that the user has to answer", () async {
      final manager = await aManager();

      await manager.checkAndAskForPermissionsAndServices(
        displayContextualIfNeeded: false,
        isAcceptanceCompulsory: true,
      );

      expect(manager.enablingWasCompulsory, isTrue);
    });

    test("answers what it already knows when it is told to ask nothing", () async {
      final manager = await aManager();

      final usable = await manager.checkAndAskForPermissionsAndServices(askActionsToUser: false);

      expect(usable, isFalse);
      expect(manager.askedEnabling, 0);
    });

    test("answers that a peripheral which has both is usable without asking", () async {
      permissions.statuses[_aPermission] = PermissionStatus.granted;
      final manager = await aManager();
      await manager.checkAndAskPermissions(displayContextualIfNeeded: false);
      manager.tellEnabled(isEnabled: true);

      final usable = await manager.checkAndAskForPermissionsAndServices(askActionsToUser: false);

      expect(usable, isTrue);
      expect(manager.askedEnabling, 0);
    });
  });
}
