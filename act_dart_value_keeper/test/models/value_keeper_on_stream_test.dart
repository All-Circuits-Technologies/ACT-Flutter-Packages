// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Turns the length of a message into the value to keep, and drops the empty messages.
int? _lengthOf(String listenedValue) => listenedValue.isEmpty ? null : listenedValue.length;

void main() {
  group("BaseValueKeeperOnStream", () {
    test("returns the initial value before the stream emits anything", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>(
        initialValue: 42,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );

      await pumpEventQueue();

      expect(keeper.value, 42);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("listens to the stream from its creation", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );

      await pumpEventQueue();
      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 4);

      await controller.close();
      await keeper.disposeLifeCycle();
    });

    test("takes the initial listened value it is given", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStream<int, String>(
        initialValue: 0,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
        initListenedValueGetter: () => "three",
      );

      await pumpEventQueue();

      expect(keeper.value, 5);

      await controller.close();
      await keeper.disposeLifeCycle();
    });
  });

  group("BaseValueKeeperOnStream.lateInitStream", () {
    test("keeps the initial value while no stream has been given", () async {
      final keeper = ValueKeeperOnStream<int, String>.lateInitStream(
        initialValue: 42,
        parserCallback: _lengthOf,
      );

      await pumpEventQueue();

      expect(keeper.value, 42);

      await keeper.disposeLifeCycle();
    });

    test("follows the stream once it has been given one", () async {
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
  });

  group("ValueKeeperOnStreamWithNullInit", () {
    test("starts without any value and takes the one the stream brings", () async {
      final controller = StreamController<String>();
      final keeper = ValueKeeperOnStreamWithNullInit<int, String>(
        initialValue: null,
        parserCallback: _lengthOf,
        listenedStream: controller.stream,
      );

      await pumpEventQueue();

      expect(keeper.value, isNull);

      controller.add("four");
      await pumpEventQueue();

      expect(keeper.value, 4);

      await controller.close();
      await keeper.disposeLifeCycle();
    });
  });
}
