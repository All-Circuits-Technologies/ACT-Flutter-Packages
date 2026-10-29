// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloTimestampedValue", () {
    test("keeps the value and the timestamp it was given", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final result = HaloTimestampedValue(value: "a", timestamp: ts);

      expect(result.value, "a");
      expect(result.timestamp, ts);
    });

    test("has no timestamp by default", () {
      expect(const HaloTimestampedValue(value: 1).timestamp, isNull);
    });

    test("is equal to another one which carries the same value and timestamp", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      expect(
        HaloTimestampedValue(value: true, timestamp: ts),
        HaloTimestampedValue(value: true, timestamp: ts),
      );
    });

    test("differs from one which carries another value", () {
      expect(
        const HaloTimestampedValue(value: 1),
        isNot(const HaloTimestampedValue(value: 2)),
      );
    });

    test("differs from one which carries another timestamp", () {
      expect(
        const HaloTimestampedValue(value: 1),
        isNot(HaloTimestampedValue(value: 1, timestamp: DateTime.utc(2024))),
      );
    });
  });
}
