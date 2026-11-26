// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BaseValueKeeper", () {
    test("returns the value it was built with", () {
      final keeper = ValueKeeper<int>(value: 42);

      expect(keeper.value, 42);
    });

    test("returns the last value which was set", () {
      final keeper = ValueKeeper<int>(value: 42)..value = 43;

      expect(keeper.value, 43);
    });

    test("keeps the value of a final object up to date", () {
      final keeper = ValueKeeper<int>(value: 0);
      void increment(ValueKeeper<int> target) => target.value = target.value + 1;

      increment(keeper);
      increment(keeper);

      expect(keeper.value, 2);
    });

    test("accepts a new value which is equal to the current one", () {
      final keeper = ValueKeeper<int>(value: 42)..value = 42;

      expect(keeper.value, 42);
    });
  });

  group("BaseValueKeeper.fromSetterValue", () {
    test("returns the value it was built with", () {
      final keeper = ValueKeeper<int>.fromSetterValue(value: 42);

      expect(keeper.value, 42);
    });

    test("builds a keeper whose value cannot be null even when the getter allows it", () {
      final keeper = ValueKeeperWithNullInit<int>.fromSetterValue(value: 42);

      expect(keeper.value, 42);
    });
  });

  group("ValueKeeperWithNullInit", () {
    test("starts without any value", () {
      final keeper = ValueKeeperWithNullInit<int>(value: null);

      expect(keeper.value, isNull);
    });

    test("holds the value once it has been set", () {
      final keeper = ValueKeeperWithNullInit<int>(value: null)..value = 42;

      expect(keeper.value, 42);
    });
  });
}
