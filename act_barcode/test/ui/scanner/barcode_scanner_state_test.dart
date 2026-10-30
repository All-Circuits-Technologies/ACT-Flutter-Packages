// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_barcode/act_barcode.dart';
import 'package:act_barcode/src/ui/scanner/barcode_scanner_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BarcodeScannerState", () {
    final running = const MobileScannerState.uninitialized().copyWith(
      isInitialized: true,
      isRunning: true,
    );

    /// Give no status, in place of the `null` literal which the linter finds redundant.
    BarcodeScannerStatus? noStatus() => null;

    test("starts without any status, and with a camera which hasn't run", () {
      const state = BarcodeScannerState.init();

      expect(state.status, isNull);
      expect(state.hasCameraRun, isFalse);
    });

    test("keeps its values when nothing is given to copy", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.scanning, hasCameraRun: true);

      expect(state.copyWith(), state);
    });

    test("takes the given status over its own", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.scanning, hasCameraRun: true);

      expect(
        state.copyWith(status: BarcodeScannerStatus.stopped).status,
        BarcodeScannerStatus.stopped,
      );
    });

    test("sets a null status only when it is forced", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.scanning, hasCameraRun: true);

      expect(state.copyWith(status: noStatus()).status, BarcodeScannerStatus.scanning);
      expect(state.copyWith(status: noStatus(), forceStatusValue: true).status, isNull);
    });

    test("is equal to a state which has the same values", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.scanning, hasCameraRun: true);

      expect(
        const BarcodeScannerState(status: BarcodeScannerStatus.scanning, hasCameraRun: true),
        state,
      );
      expect(state.copyWith(hasCameraRun: false), isNot(state));
    });

    test("tells which statuses follow the camera", () {
      const camera = {
        BarcodeScannerStatus.starting,
        BarcodeScannerStatus.scanning,
        BarcodeScannerStatus.stopped,
        BarcodeScannerStatus.error,
      };

      for (final status in BarcodeScannerStatus.values) {
        expect(
          BarcodeScannerState(status: status, hasCameraRun: false).isCameraStatus,
          camera.contains(status),
        );
      }
      expect(const BarcodeScannerState.init().isCameraStatus, isFalse);
    });

    test("copies to the statuses without camera", () {
      const state = BarcodeScannerState.init();

      expect(state.copyToUnsupportedState().status, BarcodeScannerStatus.unsupported);
      expect(state.copyToWaitingPermissionState().status, BarcodeScannerStatus.waitingPermission);
      expect(state.copyToPermissionDeniedState().status, BarcodeScannerStatus.permissionDenied);
    });

    test("copies a granted permission to starting, and forgets that the camera ran", () {
      const state = BarcodeScannerState(
        status: BarcodeScannerStatus.permissionDenied,
        hasCameraRun: true,
      );

      final copy = state.copyWithGrantedPermission(
        controllerState: const MobileScannerState.uninitialized(),
      );

      expect(copy.status, BarcodeScannerStatus.starting);
      expect(copy.hasCameraRun, isFalse);
      expect(
        state.copyWithGrantedPermission(controllerState: running).status,
        BarcodeScannerStatus.scanning,
      );
    });

    test("copies the controller state to scanning, stopped, starting and error", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.starting, hasCameraRun: false);

      final scanning = state.copyWithControllerState(controllerState: running);
      final stopped = scanning.copyWithControllerState(
        controllerState: running.copyWith(isRunning: false),
      );
      final starting = stopped.copyWithControllerState(
        controllerState: running.copyWith(isRunning: false, isStarting: true),
      );
      final error = starting.copyWithControllerState(
        controllerState: running.copyWith(
          isRunning: false,
          error: const MobileScannerException(errorCode: MobileScannerErrorCode.genericError),
        ),
      );

      expect(scanning.status, BarcodeScannerStatus.scanning);
      expect(scanning.hasCameraRun, isTrue);
      expect(stopped.status, BarcodeScannerStatus.stopped);
      expect(starting.status, BarcodeScannerStatus.starting);
      expect(error.status, BarcodeScannerStatus.error);
    });

    test("stays starting while the camera has never run", () {
      const state = BarcodeScannerState(status: BarcodeScannerStatus.starting, hasCameraRun: false);

      final copy = state.copyWithControllerState(
        controllerState: const MobileScannerState.uninitialized(),
      );

      expect(copy.status, BarcodeScannerStatus.starting);
    });
  });
}
