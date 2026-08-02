// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_qr_code/act_qr_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group("QrCodeState.init", () {
    test("knows nothing about the permission yet", () {
      expect(const QrCodeState.init().permStatus, isNull);
    });

    test("has found no code yet", () {
      expect(const QrCodeState.init().found, isFalse);
    });
  });

  group("QrCodeState", () {
    test("keeps the permission of the previous state when it is given none", () {
      final previous = PermissionResultState(
        previousState: const QrCodeState.init(),
        permissionStatus: PermissionStatus.granted,
      );

      final state = QrCodeState(previousState: previous, permissionStatus: null, found: true);

      expect(state.permStatus, PermissionStatus.granted);
    });

    test("keeps the code of the previous state when it is given none", () {
      final previous = QrCodeFoundState(previousState: _granted(), found: true);

      final state = QrCodeState(
        previousState: previous,
        permissionStatus: PermissionStatus.denied,
        found: null,
      );

      expect(state.found, isTrue);
    });

    test("refuses to be built when neither it nor the previous state knows the permission", () {
      expect(
        () => QrCodeState(
          previousState: const QrCodeState.init(),
          permissionStatus: null,
          found: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test("equals another state which carries the same permission and the same code", () {
      expect(
        QrCodeState(
          previousState: const QrCodeState.init(),
          permissionStatus: PermissionStatus.granted,
          found: true,
        ),
        QrCodeState(
          previousState: const QrCodeState.init(),
          permissionStatus: PermissionStatus.granted,
          found: true,
        ),
      );
    });

    test("differs from a state which carries another permission", () {
      expect(
        QrCodeState(
          previousState: const QrCodeState.init(),
          permissionStatus: PermissionStatus.granted,
          found: true,
        ),
        isNot(
          QrCodeState(
            previousState: const QrCodeState.init(),
            permissionStatus: PermissionStatus.denied,
            found: true,
          ),
        ),
      );
    });
  });

  group("QrCodeFoundState", () {
    test("carries the code it was built with", () {
      expect(QrCodeFoundState(previousState: _granted(), found: true).found, isTrue);
    });

    test("keeps the permission of the previous state", () {
      expect(
        QrCodeFoundState(previousState: _granted(), found: true).permStatus,
        PermissionStatus.granted,
      );
    });
  });

  group("PermissionResultState", () {
    test("carries the permission it was built with", () {
      expect(
        PermissionResultState(
          previousState: const QrCodeState.init(),
          permissionStatus: PermissionStatus.permanentlyDenied,
        ).permStatus,
        PermissionStatus.permanentlyDenied,
      );
    });

    test("keeps the code of the previous state", () {
      final previous = QrCodeFoundState(previousState: _granted(), found: true);

      expect(
        PermissionResultState(
          previousState: previous,
          permissionStatus: PermissionStatus.denied,
        ).found,
        isTrue,
      );
    });
  });
}

/// Builds the state of a reader which has been granted the permission.
QrCodeState _granted() => PermissionResultState(
  previousState: const QrCodeState.init(),
  permissionStatus: PermissionStatus.granted,
);
