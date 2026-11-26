// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BaseValueKeeperWithStream", () {
    test("returns the value it was built with", () async {
      final keeper = ValueKeeperWithStream<int>(value: 42);

      expect(keeper.value, 42);

      await keeper.disposeLifeCycle();
    });

    test("only emits a changed value by default", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);

      expect(keeper.emitUnchangedValue, isFalse);

      await keeper.disposeLifeCycle();
    });

    test("keeps the choice of emitting an unchanged value", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0, emitUnchangedValue: true);

      expect(keeper.emitUnchangedValue, isTrue);

      await keeper.disposeLifeCycle();
    });
  });

  group("ValueKeeperWithStreamAndNullInit", () {
    test("starts without any value", () async {
      final keeper = ValueKeeperWithStreamAndNullInit<int>(value: null);

      expect(keeper.value, isNull);

      await keeper.disposeLifeCycle();
    });

    test("emits the first value it is given", () async {
      final keeper = ValueKeeperWithStreamAndNullInit<int>(value: null);
      final expectation = expectLater(keeper.valueStream, emitsInOrder([42, emitsDone]));

      keeper.value = 42;
      await keeper.disposeLifeCycle();

      await expectation;
    });
  });
}
