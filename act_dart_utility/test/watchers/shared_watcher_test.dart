// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// A watcher which records when it woke up and when it went back to sleep.
class _RecordingWatcher extends SharedWatcher<_Handler> {
  final List<String> steps = [];

  _RecordingWatcher({super.thresholdDuration});

  @override
  _Handler generateHandler() => _Handler(this);

  @override
  Future<void> atFirstHandler() async => steps.add("awake");

  @override
  Future<void> whenNoMoreHandler() async => steps.add("asleep");
}

/// The handler the recording watcher hands out.
class _Handler extends SharedHandler {
  _Handler(super.watcher);
}

void main() {
  group("SharedWatcher", () {
    test("wakes up when its first handler is created", () async {
      final watcher = _RecordingWatcher();

      watcher.generateHandler();
      await pumpEventQueue();

      expect(watcher.steps, ["awake"]);
    });

    test("only wakes up once whatever the number of handlers", () async {
      final watcher = _RecordingWatcher();

      watcher
        ..generateHandler()
        ..generateHandler();
      await pumpEventQueue();

      expect(watcher.steps, ["awake"]);
    });

    test("goes back to sleep when its last handler is closed", () async {
      final watcher = _RecordingWatcher();
      final handler = watcher.generateHandler();

      await handler.close();

      expect(watcher.steps, ["awake", "asleep"]);
    });

    test("stays awake while one handler is left", () async {
      final watcher = _RecordingWatcher();
      final handler = watcher.generateHandler();
      watcher.generateHandler();
      await pumpEventQueue();

      await handler.close();

      expect(watcher.steps, ["awake"]);
    });

    test("wakes up again when a handler is created after the last one was closed", () async {
      final watcher = _RecordingWatcher();
      final handler = watcher.generateHandler();
      await handler.close();

      watcher.generateHandler();
      await pumpEventQueue();

      expect(watcher.steps, ["awake", "asleep", "awake"]);
    });

    test("does nothing when it has never had any handler", () async {
      final watcher = _RecordingWatcher();

      await pumpEventQueue();

      expect(watcher.steps, isEmpty);
    });

    test("completes its close even when it has nothing to stop", () async {
      final watcher = _RecordingWatcher();

      await expectLater(watcher.close(), completes);
    });
  });

  group("SharedWatcher threshold", () {
    test("waits the threshold before going back to sleep", () {
      fakeAsync((async) {
        final watcher = _RecordingWatcher(thresholdDuration: const Duration(seconds: 10));
        final handler = watcher.generateHandler();
        async.flushMicrotasks();

        unawaited(handler.close());
        async.flushMicrotasks();

        expect(watcher.steps, ["awake"]);

        async.elapse(const Duration(seconds: 10));

        expect(watcher.steps, ["awake", "asleep"]);
      });
    });

    test("stays awake when a handler comes back before the threshold", () {
      fakeAsync((async) {
        final watcher = _RecordingWatcher(thresholdDuration: const Duration(seconds: 10));
        final handler = watcher.generateHandler();
        async.flushMicrotasks();
        unawaited(handler.close());

        async.elapse(const Duration(seconds: 5));
        watcher.generateHandler();
        async.elapse(const Duration(seconds: 10));

        expect(watcher.steps, ["awake"]);
      });
    });
  });
}
