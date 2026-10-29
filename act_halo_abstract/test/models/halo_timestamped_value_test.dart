// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloTimestampedValue", () {
    test("keeps the value and the timestamp it was given", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final result = HaloTimestampedValue(data: "a", timestamp: ts);

      expect(result.data, "a");
      expect(result.timestamp, ts);
    });

    test("has no timestamp by default", () {
      expect(const HaloTimestampedValue(data: 1).timestamp, isNull);
    });

    test("is equal to another one which carries the same value and timestamp", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      expect(
        HaloTimestampedValue(data: true, timestamp: ts),
        HaloTimestampedValue(data: true, timestamp: ts),
      );
    });

    test("differs from one which carries another value", () {
      expect(
        const HaloTimestampedValue(data: 1),
        isNot(const HaloTimestampedValue(data: 2)),
      );
    });

    test("differs from one which carries another timestamp", () {
      expect(
        const HaloTimestampedValue(data: 1),
        isNot(HaloTimestampedValue(data: 1, timestamp: DateTime.utc(2024))),
      );
    });
  });
}
