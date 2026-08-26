// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ValueKeeperWithInitInfo.noInit", () {
    test("starts without any value", () {
      final keeper = ValueKeeperWithInitInfo<int>.noInit();

      expect(keeper.value, isNull);
    });

    test("reports that the value has not been initialised", () {
      final keeper = ValueKeeperWithInitInfo<int>.noInit();

      expect(keeper.hasBeenInitialized, isFalse);
    });

    test("reports the initialisation as soon as a value is set", () {
      final keeper = ValueKeeperWithInitInfo<int>.noInit()..value = 42;

      expect(keeper.hasBeenInitialized, isTrue);
      expect(keeper.value, 42);
    });

    test("keeps reporting the initialisation after several values", () {
      final keeper = ValueKeeperWithInitInfo<int>.noInit()
        ..value = 42
        ..value = 43;

      expect(keeper.hasBeenInitialized, isTrue);
    });
  });

  group("ValueKeeperWithInitInfo.withInit", () {
    test("returns the value it was built with", () {
      final keeper = ValueKeeperWithInitInfo<int>.withInit(value: 42);

      expect(keeper.value, 42);
    });

    test("reports the value as initialised before any setter call", () {
      final keeper = ValueKeeperWithInitInfo<int>.withInit(value: 42);

      expect(keeper.hasBeenInitialized, isTrue);
    });

    test("reports the value as initialised even when it is built with null", () {
      final keeper = ValueKeeperWithInitInfo<int>.withInit(value: null);

      expect(keeper.value, isNull);
      expect(keeper.hasBeenInitialized, isTrue);
    });
  });
}
