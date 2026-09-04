// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloCategoryType", () {
    test("gives the same raw value to the notification flags and to the keys", () {
      expect(HaloCategoryType.notifFlags.rawValue, HaloCategoryType.keys.rawValue);
    });
  });

  group("HaloCategoryType.parseValue", () {
    test("returns the data category for the raw value of the data", () {
      expect(HaloCategoryType.parseValue(HaloCategoryType.data.rawValue), HaloCategoryType.data);
    });

    test("returns the notification flags for an attribute", () {
      expect(
        HaloCategoryType.parseValue(
          HaloCategoryType.notifFlags.rawValue,
          serviceType: HaloServiceType.attribute,
        ),
        HaloCategoryType.notifFlags,
      );
    });

    test("returns the notification flags for instant data", () {
      expect(
        HaloCategoryType.parseValue(
          HaloCategoryType.notifFlags.rawValue,
          serviceType: HaloServiceType.instantData,
        ),
        HaloCategoryType.notifFlags,
      );
    });

    test("returns the keys for record data", () {
      expect(
        HaloCategoryType.parseValue(
          HaloCategoryType.keys.rawValue,
          serviceType: HaloServiceType.recordData,
        ),
        HaloCategoryType.keys,
      );
    });

    test("returns unknown for the shared raw value when the service is not given", () {
      expect(HaloCategoryType.parseValue(HaloCategoryType.keys.rawValue), HaloCategoryType.unknown);
    });

    test("returns unknown for the shared raw value when the service has no such category", () {
      expect(
        HaloCategoryType.parseValue(
          HaloCategoryType.keys.rawValue,
          serviceType: HaloServiceType.request,
        ),
        HaloCategoryType.unknown,
      );
    });

    test("returns unknown when no category carries the raw value given", () {
      expect(HaloCategoryType.parseValue(0x42), HaloCategoryType.unknown);
    });
  });
}
