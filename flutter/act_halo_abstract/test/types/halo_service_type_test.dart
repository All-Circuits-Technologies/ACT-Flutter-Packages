// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloServiceType", () {
    test("gives a distinct raw value to each service", () {
      final rawValues = HaloServiceType.values.map((service) => service.rawValue).toSet();

      expect(rawValues.length, HaloServiceType.values.length);
    });
  });

  group("HaloServiceType.parseValue", () {
    test("returns the service which carries the raw value given", () {
      expect(HaloServiceType.parseValue(0x02), HaloServiceType.recordData);
    });

    test("returns every service from its own raw value", () {
      for (final service in HaloServiceType.values) {
        expect(HaloServiceType.parseValue(service.rawValue), service);
      }
    });

    test("returns unknown when no service carries the raw value given", () {
      expect(HaloServiceType.parseValue(0x42), HaloServiceType.unknown);
    });
  });
}
