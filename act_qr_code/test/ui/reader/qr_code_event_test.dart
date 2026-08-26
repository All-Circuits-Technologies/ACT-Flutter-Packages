// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_qr_code/act_qr_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group("QrCodeFoundEvent", () {
    test("equals another event which carries the same code", () {
      expect(const QrCodeFoundEvent(found: true), const QrCodeFoundEvent(found: true));
    });

    test("differs from an event which carries no code", () {
      expect(const QrCodeFoundEvent(found: true), isNot(const QrCodeFoundEvent(found: false)));
    });
  });

  group("QrCodePermissionRetrievedEvent", () {
    test("equals another event which carries the same permission", () {
      expect(
        const QrCodePermissionRetrievedEvent(permissionStatus: PermissionStatus.granted),
        const QrCodePermissionRetrievedEvent(permissionStatus: PermissionStatus.granted),
      );
    });

    test("differs from an event which carries another permission", () {
      expect(
        const QrCodePermissionRetrievedEvent(permissionStatus: PermissionStatus.granted),
        isNot(const QrCodePermissionRetrievedEvent(permissionStatus: PermissionStatus.denied)),
      );
    });
  });
}
