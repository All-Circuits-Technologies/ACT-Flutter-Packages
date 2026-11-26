// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("EnableServiceViewContext.uniqueKey", () {
    test("names the service which has to be enabled", () {
      final context = EnableServiceViewContext(element: EnableServiceElement.ble);

      expect(context.uniqueKey, "enable_service:EnableServiceElement.ble");
    });

    test("tells two services apart", () {
      expect(
        EnableServiceViewContext(element: EnableServiceElement.ble).uniqueKey,
        isNot(EnableServiceViewContext(element: EnableServiceElement.wifi).uniqueKey),
      );
    });

    test("tells the Bluetooth apart from the Bluetooth which needs the location", () {
      expect(
        EnableServiceViewContext(element: EnableServiceElement.ble).uniqueKey,
        isNot(EnableServiceViewContext(element: EnableServiceElement.bleLocation).uniqueKey),
      );
    });
  });

  group("EnableServiceViewContext.isAcceptanceCompulsory", () {
    test("lets the user leave the page unless it is told otherwise", () {
      expect(
        EnableServiceViewContext(element: EnableServiceElement.ble).isAcceptanceCompulsory,
        isFalse,
      );
    });

    test("keeps the user on the page when the service has to be enabled", () {
      final context = EnableServiceViewContext(
        element: EnableServiceElement.ble,
        isAcceptanceCompulsory: true,
      );

      expect(context.isAcceptanceCompulsory, isTrue);
    });
  });

  group("EnableServiceViewContext", () {
    test("is the same reason as one of the same service", () {
      expect(
        EnableServiceViewContext(element: EnableServiceElement.ble),
        EnableServiceViewContext(element: EnableServiceElement.ble, isAcceptanceCompulsory: true),
      );
    });

    test("is not the same reason as one of another service", () {
      expect(
        EnableServiceViewContext(element: EnableServiceElement.ble),
        isNot(EnableServiceViewContext(element: EnableServiceElement.location)),
      );
    });
  });
}
