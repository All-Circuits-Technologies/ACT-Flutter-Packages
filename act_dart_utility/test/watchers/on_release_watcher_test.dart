// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("OnReleaseWatcher", () {
    test("calls the callback when the last handler is released", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () => calls++);
      final handler = watcher.generateHandler();

      await handler.close();

      expect(calls, 1);
    });

    test("waits for every handler to be released", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () => calls++);
      final handler = watcher.generateHandler();
      final otherHandler = watcher.generateHandler();
      await pumpEventQueue();

      await handler.close();

      expect(calls, 0);

      await otherHandler.close();

      expect(calls, 1);
    });

    test("does not call the callback while no handler has been created", () async {
      var calls = 0;
      OnReleaseWatcher(callback: () => calls++);

      await pumpEventQueue();

      expect(calls, 0);
    });

    test("hands out handlers of its own kind", () {
      final watcher = OnReleaseWatcher(callback: () {});

      expect(watcher.generateHandler(), isA<OnReleaseHandler>());
    });

    test("takes a new callback after its creation", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () {})..callback = () => calls++;
      final handler = watcher.generateHandler();

      await handler.close();

      expect(calls, 1);
    });
  });

  group("OnReleaseWatcher.supervise", () {
    test("returns the result of the critical section", () async {
      final watcher = OnReleaseWatcher(callback: () {});

      expect(await watcher.supervise(() async => 42), 42);
    });

    test("calls the callback once the critical section is over", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () => calls++);

      await watcher.supervise(() async {
        expect(calls, 0);
        return null;
      });

      expect(calls, 1);
    });

    test("releases the handler even when the critical section throws", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () => calls++);

      await expectLater(
        watcher.supervise(() async => throw Exception("boom")),
        throwsException,
      );

      expect(calls, 1);
    });

    test("only calls the callback once two nested sections are over", () async {
      var calls = 0;
      final watcher = OnReleaseWatcher(callback: () => calls++);

      await watcher.supervise(() async {
        await watcher.supervise(() async {});
        expect(calls, 0);
      });

      expect(calls, 1);
    });
  });
}
