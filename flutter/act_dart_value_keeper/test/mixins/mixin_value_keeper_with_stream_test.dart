// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

// The mixin is tested through the simplest keeper which carries it.

void main() {
  group("MixinValueKeeperWithStream.valueStream", () {
    test("emits the new value when the value changes", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      keeper
        ..value = 1
        ..value = 2;
      await pumpEventQueue();

      expect(emitted, [1, 2]);

      await subscription.cancel();
      await keeper.disposeLifeCycle();
    });

    test("does not emit the value it was built with", () async {
      final keeper = ValueKeeperWithStream<int>(value: 42);
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();

      expect(emitted, isEmpty);

      await subscription.cancel();
      await keeper.disposeLifeCycle();
    });

    test("drops a value which is equal to the current one", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      keeper
        ..value = 1
        ..value = 1
        ..value = 2;
      await pumpEventQueue();

      expect(emitted, [1, 2]);

      await subscription.cancel();
      await keeper.disposeLifeCycle();
    });

    test("emits an unchanged value when it is asked to", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0, emitUnchangedValue: true);
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      keeper
        ..value = 1
        ..value = 1;
      await pumpEventQueue();

      expect(emitted, [1, 1]);

      await subscription.cancel();
      await keeper.disposeLifeCycle();
    });

    test("serves several listeners at once", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);
      final emitted = <int>[];
      final otherEmitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);
      final otherSubscription = keeper.valueStream.listen(otherEmitted.add);

      keeper.value = 1;
      await pumpEventQueue();

      expect(emitted, [1]);
      expect(otherEmitted, [1]);

      await subscription.cancel();
      await otherSubscription.cancel();
      await keeper.disposeLifeCycle();
    });

    test("keeps the value up to date even without any listener", () {
      final keeper = ValueKeeperWithStream<int>(value: 0)..value = 1;

      expect(keeper.value, 1);
    });
  });

  group("MixinValueKeeperWithStream.disposeLifeCycle", () {
    test("closes the stream", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);
      final done = expectLater(keeper.valueStream, emitsDone);

      await keeper.disposeLifeCycle();

      await done;
    });

    test("emits the values which were set before the close", () async {
      final keeper = ValueKeeperWithStream<int>(value: 0);
      final expectation = expectLater(keeper.valueStream, emitsInOrder([1, 2, emitsDone]));

      keeper
        ..value = 1
        ..value = 2;
      await keeper.disposeLifeCycle();

      await expectation;
    });
  });
}
