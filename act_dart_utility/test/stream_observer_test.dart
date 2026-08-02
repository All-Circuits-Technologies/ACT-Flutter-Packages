// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// An observer which considers a level valid as long as it stays above zero.
class _LevelObserver extends StreamObserver<int> {
  _LevelObserver({required super.stream, required super.get});

  @override
  bool isNewValueValid(int value) => value > 0;
}

void main() {
  late StreamController<int> controller;

  setUp(() => controller = StreamController<int>.broadcast());
  tearDown(() => controller.close());

  group("StreamObserver", () {
    test("takes its first validity from the current value", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);

      expect(observer.isValid, isTrue);

      await observer.dispose();
    });

    test("reports an invalid current value", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 0);

      expect(observer.isValid, isFalse);

      await observer.dispose();
    });

    test("follows the values brought by the stream", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);

      controller.add(0);
      await pumpEventQueue();

      expect(observer.isValid, isFalse);

      controller.add(1);
      await pumpEventQueue();

      expect(observer.isValid, isTrue);

      await observer.dispose();
    });
  });

  group("StreamObserver.stream", () {
    test("emits when the validity changes", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);
      final emitted = <bool>[];
      final subscription = observer.stream.listen(emitted.add);

      controller
        ..add(0)
        ..add(1);
      await pumpEventQueue();

      expect(emitted, [false, true]);

      await subscription.cancel();
      await observer.dispose();
    });

    test("stays quiet while the validity does not change", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);
      final emitted = <bool>[];
      final subscription = observer.stream.listen(emitted.add);

      controller
        ..add(6)
        ..add(7);
      await pumpEventQueue();

      expect(emitted, isEmpty);

      await subscription.cancel();
      await observer.dispose();
    });

    test("does not emit the validity it started with", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 0);
      final emitted = <bool>[];
      final subscription = observer.stream.listen(emitted.add);

      await pumpEventQueue();

      expect(emitted, isEmpty);

      await subscription.cancel();
      await observer.dispose();
    });

    test("serves several listeners at once", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);
      final emitted = <bool>[];
      final otherEmitted = <bool>[];
      final subscription = observer.stream.listen(emitted.add);
      final otherSubscription = observer.stream.listen(otherEmitted.add);

      controller.add(0);
      await pumpEventQueue();

      expect(emitted, [false]);
      expect(otherEmitted, [false]);

      await subscription.cancel();
      await otherSubscription.cancel();
      await observer.dispose();
    });
  });

  group("StreamObserver.dispose", () {
    test("closes the stream", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);
      final done = expectLater(observer.stream, emitsDone);

      await observer.dispose();

      await done;
    });

    test("stops following the observed stream", () async {
      final observer = _LevelObserver(stream: controller.stream, get: () => 5);

      await observer.dispose();
      controller.add(0);
      await pumpEventQueue();

      expect(observer.isValid, isTrue);
    });
  });
}
