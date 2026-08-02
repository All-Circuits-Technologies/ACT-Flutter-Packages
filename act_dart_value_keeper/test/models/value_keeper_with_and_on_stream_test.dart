// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Turns the length of a message into the value to keep, and drops the empty messages.
int? _lengthOf(String listenedValue) => listenedValue.isEmpty ? null : listenedValue.length;

void main() {
  group("BaseValueKeeperWithAndOnStream", () {
    test("emits what the listened stream brought", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();
      controller
        ..add("four")
        ..add("a");
      await pumpEventQueue();

      expect(emitted, [4, 1]);
      expect(keeper.value, 1);

      await subscription.cancel();
      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("emits nothing when the parser drops the listened value", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();
      controller.add("");
      await pumpEventQueue();

      expect(emitted, isEmpty);

      await subscription.cancel();
      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("emits nothing when the listened stream brings the same value again", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();
      controller
        ..add("four")
        ..add("five");
      await pumpEventQueue();

      expect(emitted, [4]);

      await subscription.cancel();
      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("emits the same value again when it is asked to", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
        emitUnchangedValue: true,
      );
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();
      controller
        ..add("four")
        ..add("five");
      await pumpEventQueue();

      expect(emitted, [4, 4]);

      await subscription.cancel();
      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("also emits the values which are set directly", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );
      final emitted = <int>[];
      final subscription = keeper.valueStream.listen(emitted.add);

      await pumpEventQueue();
      keeper.value = 42;
      await pumpEventQueue();

      expect(emitted, [42]);

      await subscription.cancel();
      await controller.close();
      await keeper.disposeLifeCycle();
    });
  });

  group("BaseValueKeeperWithAndOnStream.lateInitStream", () {
    test("keeps the initial value while no stream has been given", () async {
      final keeper = ValueKeeperWithAndOnStream<int, String>.lateInitStream(
        initialValue: 42,
        parserCallback: _lengthOf,
      );

      await pumpEventQueue();

      expect(keeper.value, 42);

      await keeper.disposeLifeCycle();
    });
  });

  group("BaseValueKeeperWithAndOnStream.disposeLifeCycle", () {
    test("closes the stream and stops listening to the other one", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperWithAndOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );
      final expectation = expectLater(keeper.valueStream, emitsDone);

      await pumpEventQueue();
      await keeper.disposeLifeCycle();
      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 0);
      await expectation;

      await controller.close();
    });
  });
}
