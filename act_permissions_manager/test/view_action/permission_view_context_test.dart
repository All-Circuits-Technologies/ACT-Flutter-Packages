// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("PermissionViewContext.uniqueKey", () {
    test("names the element and the action it stands for", () {
      final context = PermissionViewContext(
        element: PermissionElement.ble,
        action: PermissionViewAction.askPermission,
      );

      expect(
        context.uniqueKey,
        "permission:PermissionElement.ble:PermissionViewAction.askPermission",
      );
    });

    test("tells two actions of the same element apart", () {
      final asking = PermissionViewContext(
        element: PermissionElement.ble,
        action: PermissionViewAction.askPermission,
      );
      final informing = PermissionViewContext(
        element: PermissionElement.ble,
        action: PermissionViewAction.informPermanentlyDenied,
      );

      expect(asking.uniqueKey, isNot(informing.uniqueKey));
    });

    test("tells the same action of two elements apart", () {
      final ble = PermissionViewContext(
        element: PermissionElement.ble,
        action: PermissionViewAction.askPermission,
      );
      final wifi = PermissionViewContext(
        element: PermissionElement.wifi,
        action: PermissionViewAction.askPermission,
      );

      expect(ble.uniqueKey, isNot(wifi.uniqueKey));
    });
  });

  group("PermissionViewContext.askPermission", () {
    test("stands for the permission which is asked of the user", () {
      final context = PermissionViewContext.askPermission(element: PermissionElement.ble);

      expect(context.element, PermissionElement.ble);
      expect(context.action, PermissionViewAction.askPermission);
    });

    test("lets the user leave the page unless it is told otherwise", () {
      final context = PermissionViewContext.askPermission(element: PermissionElement.ble);

      expect(context.isAcceptanceCompulsory, isFalse);
    });

    test("keeps the user on the page when the permission has to be granted", () {
      final context = PermissionViewContext.askPermission(
        element: PermissionElement.ble,
        isAcceptanceCompulsory: true,
      );

      expect(context.isAcceptanceCompulsory, isTrue);
    });
  });

  group("PermissionViewContext.informPermanentlyDenied", () {
    test("stands for the permission which was refused for good", () {
      final context = PermissionViewContext.informPermanentlyDenied(
        element: PermissionElement.ble,
      );

      expect(context.element, PermissionElement.ble);
      expect(context.action, PermissionViewAction.informPermanentlyDenied);
    });

    test("lets the user leave the page, since there is nothing left to grant", () {
      final context = PermissionViewContext.informPermanentlyDenied(
        element: PermissionElement.ble,
      );

      expect(context.isAcceptanceCompulsory, isFalse);
    });
  });

  group("PermissionViewContext", () {
    test("is the same reason as one of the same element and action", () {
      expect(
        PermissionViewContext.askPermission(element: PermissionElement.ble),
        PermissionViewContext(
          element: PermissionElement.ble,
          action: PermissionViewAction.askPermission,
        ),
      );
    });

    test("is not the same reason as one of another element", () {
      expect(
        PermissionViewContext.askPermission(element: PermissionElement.ble),
        isNot(PermissionViewContext.askPermission(element: PermissionElement.wifi)),
      );
    });
  });
}
