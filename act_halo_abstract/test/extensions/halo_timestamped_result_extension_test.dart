// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloTimestampedResultExtension", () {
    test("reads the value and the timestamp of a success", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);
      final result = BoolResultWithRequiredValue.fromValue(
        value: HaloTimestampedValue(data: 42, timestamp: ts),
      );

      expect(result.data, 42);
      expect(result.timestamp, ts);
    });

    test("reads no timestamp from a success which carries none", () {
      const result = BoolResultWithRequiredValue.fromValue(
        value: HaloTimestampedValue(data: "a"),
      );

      expect(result.data, "a");
      expect(result.timestamp, isNull);
    });

    test("reads nothing from an error", () {
      const result = BoolResultWithRequiredValue<HaloTimestampedValue<int>>.error();

      expect(result.data, isNull);
      expect(result.timestamp, isNull);
    });
  });
}
