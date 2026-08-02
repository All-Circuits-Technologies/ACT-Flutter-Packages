// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloRequestType", () {
    test("gives a raw value which fits in a byte to every type the device knows", () {
      final exchanged = HaloRequestType.values.where((type) => type != HaloRequestType.unknown);

      expect(exchanged.map((type) => type.rawValue), everyElement(inInclusiveRange(0x00, 0xFF)));
    });

    test("gives a distinct raw value to each type", () {
      final rawValues = HaloRequestType.values.map((type) => type.rawValue).toSet();

      expect(rawValues.length, HaloRequestType.values.length);
    });
  });

  group("HaloRequestType.parseValue", () {
    test("returns the type which carries the raw value given", () {
      expect(HaloRequestType.parseValue(0x01), HaloRequestType.procedure);
    });

    test("returns every type from its own raw value", () {
      for (final type in HaloRequestType.values) {
        expect(HaloRequestType.parseValue(type.rawValue), type);
      }
    });

    test("returns unknown when no type carries the raw value given", () {
      expect(HaloRequestType.parseValue(0x42), HaloRequestType.unknown);
    });
  });
}
