// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_barcode/src/ui/scanner/barcode_scanner_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group("BarcodeScannerEvent", () {
    test("considers two permission events equal when the permission is the same", () {
      expect(
        const BarcodeScannerPermissionEvent(isGranted: true),
        const BarcodeScannerPermissionEvent(isGranted: true),
      );
      expect(
        const BarcodeScannerPermissionEvent(isGranted: true),
        isNot(const BarcodeScannerPermissionEvent(isGranted: false)),
      );
    });

    test("considers two ask permission events equal", () {
      expect(const BarcodeScannerAskPermissionEvent(), const BarcodeScannerAskPermissionEvent());
    });

    test("considers two controller events equal when the camera is in the same condition", () {
      const state = MobileScannerState.uninitialized();

      expect(
        const BarcodeScannerControllerEvent(controllerState: state),
        const BarcodeScannerControllerEvent(controllerState: state),
      );
      expect(
        const BarcodeScannerControllerEvent(controllerState: state),
        isNot(BarcodeScannerControllerEvent(controllerState: state.copyWith(isRunning: true))),
      );
    });
  });
}
