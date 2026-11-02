// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_barcode/act_barcode.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart' show MobileScanner;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import '../../fakes/fake_app_life_cycle_manager.dart';
import '../../fakes/fake_mobile_scanner.dart';
import '../../fakes/fake_permissions_platform.dart';
import '../../fakes/fake_platform_manager.dart';

/// Give the text the tests use for each message of the widget.
String _text(BuildContext context, BarcodeScannerText text) => text.name;

void main() {
  late FakeGlobalManager globalManager;
  late FakePermissionsPlatform permissions;
  late FakeAppLifeCycleManager lifeCycle;
  late FakeMobileScannerPlatform scanner;

  /// Register the platform the application runs on, in the global manager.
  void registerPlatform(FakePlatformManager platform) {
    globalGetIt()
      ..registerSingleton<PlatformManager>(platform)
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());
  }

  /// Display a scanner in a space which is at most 400 by 300, without any page to explain.
  Widget aScanner({
    void Function(Barcode barcode)? onCodeFound,
    bool Function(Barcode barcode)? validator,
    MobileScannerController? controller,
    double? width,
    double? height,
    Widget Function(BuildContext context, BarcodeScannerStatus status)? overlayBuilder,
    void Function(BarcodeScannerStatus status)? onStatusChanged,
  }) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(const Size(400, 300)),
          child: BarcodeScannerWidget(
            textGetter: _text,
            onCodeFound: onCodeFound ?? (_) {},
            validator: validator,
            controller: controller,
            width: width,
            height: height,
            overlayBuilder: overlayBuilder,
            onStatusChanged: onStatusChanged,
            displayContextualIfNeeded: false,
          ),
        ),
      ),
    ),
  );

  /// Let the permission be read, the camera be started and the widget be built again.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    // A refused permission is read again by the manager for a while
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Let the bloc, which the removed widget closes, release what it owns.
  ///
  /// Closing the bloc waits for streams, which the event loop of the test, not the pumps alone,
  /// completes.
  Future<void> settleClose(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  setUp(() {
    globalManager = FakeGlobalManager.install();
    permissions = FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    scanner = FakeMobileScannerPlatform.install();
    MobileScannerController.resetPlatformSessionOwner();
    registerPlatform(FakePlatformManager.android(version: 34));
  });

  tearDown(() async {
    await lifeCycle.close();
    await globalManager.reset();
  });

  group("BarcodeScannerWidget status", () {
    testWidgets("says that the platform is unsupported on Linux", (tester) async {
      await globalManager.reset();
      globalManager = FakeGlobalManager.install();
      registerPlatform(FakePlatformManager(isLinux: true));

      await tester.pumpWidget(aScanner());
      await settle(tester);

      expect(find.text(BarcodeScannerText.unsupportedPlatform.name), findsOneWidget);
      expect(permissions.requested, isEmpty);
    });

    testWidgets("says that it waits for the permission", (tester) async {
      permissions.gate = Completer<void>();

      await tester.pumpWidget(aScanner());
      await settle(tester);

      expect(find.text(BarcodeScannerText.waitingPermission.name), findsOneWidget);

      permissions.gate!.complete();
      await settle(tester);
    });

    testWidgets("says that the permission is denied and offers to ask it again", (tester) async {
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;

      await tester.pumpWidget(aScanner());
      await settle(tester);

      expect(find.text(BarcodeScannerText.permissionDenied.name), findsOneWidget);
      expect(find.text(BarcodeScannerText.askPermissionButton.name), findsOneWidget);
    });

    testWidgets("asks the permission again when the button is pressed", (tester) async {
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;
      await tester.pumpWidget(aScanner());
      await settle(tester);

      permissions.answersToRequest[Permission.camera] = PermissionStatus.granted;
      await tester.tap(find.text(BarcodeScannerText.askPermissionButton.name));
      await settle(tester);

      expect(permissions.requested, [Permission.camera, Permission.camera]);
      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.text(BarcodeScannerText.permissionDenied.name), findsNothing);
    });

    testWidgets("shows the camera and scans once the permission is granted", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final statuses = <BarcodeScannerStatus>[];

      await tester.pumpWidget(aScanner(onStatusChanged: statuses.add));
      await settle(tester);

      expect(find.byType(MobileScanner), findsOneWidget);
      expect(scanner.startCount, 1);
      expect(statuses, [
        BarcodeScannerStatus.waitingPermission,
        BarcodeScannerStatus.starting,
        BarcodeScannerStatus.scanning,
      ]);
    });

    testWidgets("tells that the camera is stopped when the controller pauses it", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final controller = MobileScannerController();
      addTearDown(controller.dispose);
      final statuses = <BarcodeScannerStatus>[];
      await tester.pumpWidget(aScanner(controller: controller, onStatusChanged: statuses.add));
      await settle(tester);

      await controller.pause();
      await settle(tester);

      expect(statuses.last, BarcodeScannerStatus.stopped);
      expect(scanner.pauseCount, 1);
    });

    testWidgets("says that the camera failed", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      scanner.startError = const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      final statuses = <BarcodeScannerStatus>[];

      await tester.pumpWidget(aScanner(onStatusChanged: statuses.add));
      await settle(tester);

      expect(find.text(BarcodeScannerText.cameraError.name), findsOneWidget);
      expect(statuses.last, BarcodeScannerStatus.error);
    });

    testWidgets("keeps its status when it is built again", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      await tester.pumpWidget(aScanner());
      await settle(tester);

      await tester.pumpWidget(aScanner(width: 100));
      await settle(tester);

      expect(find.byType(MobileScanner), findsOneWidget);
      expect(scanner.startCount, 1);
    });
  });

  group("BarcodeScannerWidget codes", () {
    const accepted = Barcode(rawValue: "ACT-1", format: BarcodeFormat.qrCode);
    const refused = Barcode(rawValue: "OTHER", format: BarcodeFormat.code128);
    const empty = Barcode();

    testWidgets("gives the codes the validator accepts, and only them", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final found = <Barcode>[];
      await tester.pumpWidget(
        aScanner(
          onCodeFound: found.add,
          validator: (barcode) => barcode.rawValue?.startsWith("ACT-") ?? false,
        ),
      );
      await settle(tester);

      scanner.emit([refused, accepted]);
      await settle(tester);

      expect(found, [accepted]);
    });

    testWidgets("gives all the codes when there is no validator", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final found = <Barcode>[];
      await tester.pumpWidget(aScanner(onCodeFound: found.add));
      await settle(tester);

      scanner.emit([refused, accepted]);
      await settle(tester);

      expect(found, [refused, accepted]);
    });

    testWidgets("ignores the codes which have neither a value nor bytes", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final found = <Barcode>[];
      await tester.pumpWidget(aScanner(onCodeFound: found.add));
      await settle(tester);

      scanner.emit([empty, accepted]);
      await settle(tester);

      expect(found, [accepted]);
    });
  });

  group("BarcodeScannerWidget overlay", () {
    testWidgets("draws the overlay over the camera with the current status", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;

      await tester.pumpWidget(
        aScanner(overlayBuilder: (context, status) => Text("overlay ${status.name}")),
      );
      await settle(tester);

      expect(find.text("overlay scanning"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("overlay scanning")).dx,
        greaterThanOrEqualTo(tester.getTopLeft(find.byType(MobileScanner)).dx),
      );
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets("draws no overlay while there is no camera", (tester) async {
      permissions.answersToRequest[Permission.camera] = PermissionStatus.denied;

      await tester.pumpWidget(
        aScanner(overlayBuilder: (context, status) => Text("overlay ${status.name}")),
      );
      await settle(tester);

      expect(find.textContaining("overlay"), findsNothing);
    });
  });

  group("BarcodeScannerWidget size", () {
    /// Give the size of the scanner displayed.
    Size sizeOf(WidgetTester tester) => tester.getSize(find.byType(BarcodeScannerWidget));

    testWidgets("is a square of the smallest available side by default", (tester) async {
      await tester.pumpWidget(aScanner());
      await settle(tester);

      expect(sizeOf(tester), const Size(300, 300));
    });

    testWidgets("takes the available height when only the width is given", (tester) async {
      await tester.pumpWidget(aScanner(width: 100));
      await settle(tester);

      expect(sizeOf(tester), const Size(100, 300));
    });

    testWidgets("takes the available width when only the height is given", (tester) async {
      await tester.pumpWidget(aScanner(height: 100));
      await settle(tester);

      expect(sizeOf(tester), const Size(400, 100));
    });

    testWidgets("has the given dimensions when both are given", (tester) async {
      await tester.pumpWidget(aScanner(width: 120, height: 80));
      await settle(tester);

      expect(sizeOf(tester), const Size(120, 80));
    });
  });

  group("BarcodeScannerWidget controller", () {
    testWidgets("disposes the controller it created", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      await tester.pumpWidget(aScanner());
      await settle(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await settleClose(tester);

      expect(scanner.disposeCount, 1);
    });

    testWidgets("doesn't dispose the controller it was given", (tester) async {
      permissions.statuses[Permission.camera] = PermissionStatus.granted;
      final controller = MobileScannerController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(aScanner(controller: controller));
      await settle(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await settleClose(tester);

      expect(scanner.disposeCount, 0);
      expect(() => controller.addListener(() {}), returnsNormally);
    });
  });
}
