// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_barcode/act_barcode.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_bloc.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_event.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../../fakes/fake_app_life_cycle_manager.dart';
import '../../fakes/fake_mobile_scanner.dart';
import '../../fakes/fake_permissions_platform.dart';
import '../../fakes/fake_platform_manager.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeAppLifeCycleManager lifeCycle;
  late MobileScannerController controller;
  late FakeMobileScannerPlatform scanner;

  /// Register the platform the application runs on, in the global manager.
  void registerPlatform(FakePlatformManager platform) {
    globalGetIt()
      ..registerSingleton<PlatformManager>(platform)
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());
  }

  /// Create a bloc which doesn't display any page of the application, and which is closed after
  /// the test.
  ///
  /// The statuses it emits are added to [statuses]. The bloc uses the controller of the test,
  /// unless [withOwnController] is true.
  BarcodeScannerBloc aBloc(List<BarcodeScannerStatus> statuses, {bool withOwnController = false}) {
    final bloc = BarcodeScannerBloc(
      controller: withOwnController ? null : controller,
      displayContextualIfNeeded: false,
    );
    bloc.stream.listen((state) {
      final status = state.status;

      if (status != null) {
        statuses.add(status);
      }
    });
    addTearDown(() async {
      if (!bloc.isClosed) {
        await bloc.close();
      }
    });

    return bloc;
  }

  /// Wait for a refused permission to be answered: the manager reads it again for a while.
  Future<void> waitForRefusal() => Future<void>.delayed(const Duration(seconds: 1));

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    controller = MobileScannerController(autoStart: false);
    scanner = FakeMobileScannerPlatform.install();
    MobileScannerController.resetPlatformSessionOwner();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await controller.dispose();
    await lifeCycle.close();
    await globalManager.reset();
  });

  group("BarcodeScannerBloc", () {
    for (final entry in {
      "Linux": FakePlatformManager(isLinux: true),
      "Windows": FakePlatformManager(isWindows: true),
      "Fuchsia": FakePlatformManager(isFuchsia: true),
    }.entries) {
      test("is unsupported on ${entry.key} and asks nothing to the device", () async {
        registerPlatform(entry.value);
        final statuses = <BarcodeScannerStatus>[];

        final bloc = aBloc(statuses);
        await pumpEventQueue();

        expect(bloc.state.status, BarcodeScannerStatus.unsupported);
        expect(statuses, [BarcodeScannerStatus.unsupported]);
        expect(permissions.requested, isEmpty);
      });
    }

    test("waits for the permission, then starts when it is already granted", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];

      final bloc = aBloc(statuses);

      expect(bloc.state.status, isNull);

      await pumpEventQueue();

      expect(statuses, [BarcodeScannerStatus.waitingPermission, BarcodeScannerStatus.starting]);
      expect(permissions.requested, isEmpty);
    });

    test("starts when the permission is asked and then granted", () async {
      registerPlatform(FakePlatformManager.ios());
      permissions.statuses[Permission.camera] = PermissionStatus.denied;
      final statuses = <BarcodeScannerStatus>[];

      aBloc(statuses);
      await pumpEventQueue();

      expect(statuses, [BarcodeScannerStatus.waitingPermission, BarcodeScannerStatus.starting]);
      expect(permissions.requested, [Permission.camera]);
    });

    test("is denied when the permission is refused", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;
      final statuses = <BarcodeScannerStatus>[];

      aBloc(statuses);
      await waitForRefusal();

      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.permissionDenied,
      ]);
    });

    test("starts when the permission is asked again after a refusal and then granted", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;
      final statuses = <BarcodeScannerStatus>[];
      final bloc = aBloc(statuses);
      await waitForRefusal();

      permissions.answersToRequest[Permission.camera] = PermissionStatus.granted;
      bloc.add(const BarcodeScannerAskPermissionEvent());
      await pumpEventQueue();

      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.permissionDenied,
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.starting,
      ]);
    });

    test("starts when the permission is granted in the settings while denied", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;
      final statuses = <BarcodeScannerStatus>[];
      aBloc(statuses);
      await waitForRefusal();

      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.permissionDenied,
        BarcodeScannerStatus.starting,
      ]);
    });

    test("is denied again when the permission is withdrawn in the settings", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];
      aBloc(statuses);
      await pumpEventQueue();

      permissions.statuses[Permission.camera] = PermissionStatus.denied;
      await lifeCycle.goTo(AppLifecycleState.paused);
      await lifeCycle.goTo(AppLifecycleState.resumed);
      await waitForRefusal();

      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.starting,
        BarcodeScannerStatus.permissionDenied,
      ]);
    });

    test("follows the controller once the permission is granted", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];
      aBloc(statuses);
      await pumpEventQueue();

      controller.value = controller.value.copyWith(isInitialized: true, isRunning: true);
      await pumpEventQueue();
      controller.value = controller.value.copyWith(isRunning: false);
      await pumpEventQueue();
      controller.value = controller.value.copyWith(isStarting: true);
      await pumpEventQueue();
      controller.value = controller.value.copyWith(
        isStarting: false,
        error: const MobileScannerException(errorCode: MobileScannerErrorCode.genericError),
      );
      await pumpEventQueue();

      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.starting,
        BarcodeScannerStatus.scanning,
        BarcodeScannerStatus.stopped,
        BarcodeScannerStatus.starting,
        BarcodeScannerStatus.error,
      ]);
    });

    test("is starting, not stopped, while the camera has never run", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];
      final bloc = aBloc(statuses);
      await pumpEventQueue();

      controller.value = controller.value.copyWith(isInitialized: true);
      await pumpEventQueue();

      expect(bloc.state.status, BarcodeScannerStatus.starting);
    });

    test("ignores the controller while the permission is denied", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;
      final statuses = <BarcodeScannerStatus>[];
      final bloc = aBloc(statuses);
      await waitForRefusal();

      controller.value = controller.value.copyWith(isInitialized: true, isRunning: true);
      await pumpEventQueue();

      expect(bloc.state.status, BarcodeScannerStatus.permissionDenied);
    });

    test("stops following the controller once it is closed", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];
      final bloc = aBloc(statuses);
      await pumpEventQueue();

      await bloc.close();
      controller.value = controller.value.copyWith(isInitialized: true, isRunning: true);
      await pumpEventQueue();

      expect(statuses, [BarcodeScannerStatus.waitingPermission, BarcodeScannerStatus.starting]);
    });

    test("disposes the controller it created, and not the one it was given", () async {
      registerPlatform(FakePlatformManager.android(version: 34));
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final owner = aBloc([], withOwnController: true);
      final borrower = aBloc([]);
      await pumpEventQueue();

      await borrower.close();

      expect(scanner.disposeCount, 0);
      expect(borrower.controller, same(controller));

      await owner.close();

      expect(scanner.disposeCount, 1);
    });
  });
}
