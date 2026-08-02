// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

// The mixin is tested through the simplest keeper which carries it.

/// Turns the length of a message into the value to keep, and drops the empty messages.
int? _lengthOf(String listenedValue) => listenedValue.isEmpty ? null : listenedValue.length;

void main() {
  group("MixinValueKeeperOnStreamUpdate.initStreamListener", () {
    test("updates the value with what the parser returns", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(listenedStream: controller.stream);
      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 4);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("keeps the current value when the parser returns null", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 42,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(listenedStream: controller.stream);
      controller.add("");
      await pumpEventQueue();

      expect(keeper.value, 42);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("applies the initial listened value it is given", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(
        listenedStream: controller.stream,
        initListenedValueGetter: () => "three",
      );

      expect(keeper.value, 5);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("waits for an asynchronous initial listened value", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(
        listenedStream: controller.stream,
        initListenedValueGetter: () async => "three",
      );

      expect(keeper.value, 5);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("keeps the initial value when the getter returns null", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 42,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(
        listenedStream: controller.stream,
        initListenedValueGetter: () => null,
      );

      expect(keeper.value, 42);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("stops listening to the previous stream when it is called again", () async {
      final controller = StreamController<String>();
      final otherController = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(listenedStream: controller.stream);
      await keeper.initStreamListener(listenedStream: otherController.stream);
      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 0);

      otherController.add("four");
      await pumpEventQueue();

      expect(keeper.value, 4);

      await controller.close();
      await otherController.close();
      await keeper.disposeLifeCycle();
    });
  });

  group("MixinValueKeeperOnStreamUpdate.disposeLifeCycle", () {
    test("stops listening to the stream", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await keeper.initStreamListener(listenedStream: controller.stream);
      await keeper.disposeLifeCycle();
      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 0);

      await controller.close();
    });

    test("completes even when no stream has been listened to", () async {
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 0,
        parserCallback: _lengthOf,
      );

      await expectLater(keeper.disposeLifeCycle(), completes);
    });
  });
}
