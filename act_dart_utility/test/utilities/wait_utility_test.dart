// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// A source which holds a status and emits the changes.
class _StatusSource {
  final StreamController<String> controller = StreamController<String>.broadcast();

  String status = "idle";

  void emit(String newStatus) {
    status = newStatus;
    controller.add(newStatus);
  }

  Future<void> close() => controller.close();
}

void main() {
  late _StatusSource source;

  setUp(() => source = _StatusSource());
  tearDown(() => source.close());

  group("WaitUtility.waitForStatus", () {
    test("returns at once when the status is already the expected one", () async {
      source.status = "ready";

      final status = await WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
      );

      expect(status, "ready");
    });

    test("waits for the stream to bring the expected status", () async {
      final future = WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
      );

      await pumpEventQueue();
      source.emit("ready");

      expect(await future, "ready");
    });

    test("ignores the statuses which are not the expected one", () async {
      final future = WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
      );

      await pumpEventQueue();
      source
        ..emit("starting")
        ..emit("ready");

      expect(await future, "ready");
    });

    test("runs the action while it listens to the statuses", () async {
      final status = await WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
        doAction: () {
          source.emit("ready");
          return true;
        },
      );

      expect(status, "ready");
    });

    test("returns the current status when the action reports a problem", () async {
      final status = await WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
        doAction: () => false,
      );

      expect(status, "idle");
    });

    test("returns the current status when the timeout is reached", () async {
      final status = await WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        valueGetter: () => source.status,
        statusEmitter: source.controller.stream,
        timeout: const Duration(milliseconds: 20),
      );

      expect(status, "idle");
    });

    test("accepts an asynchronous test of the status", () async {
      final future = WaitUtility.waitForStatus<String>(
        isExpectedStatus: (status) async => status == "ready",
        valueGetter: () async => source.status,
        statusEmitter: source.controller.stream,
      );

      await pumpEventQueue();
      source.emit("ready");

      expect(await future, "ready");
    });
  });

  group("WaitUtility.nullableWaitForStatus", () {
    test("waits for the expected status without any value getter", () async {
      final future = WaitUtility.nullableWaitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        statusEmitter: source.controller.stream,
      );

      await pumpEventQueue();
      source.emit("ready");

      expect(await future, "ready");
    });

    test("returns null when the timeout is reached and there is no value getter", () async {
      final status = await WaitUtility.nullableWaitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        statusEmitter: source.controller.stream,
        timeout: const Duration(milliseconds: 20),
      );

      expect(status, isNull);
    });

    test("returns null when the action reports a problem and there is no value getter", () async {
      final status = await WaitUtility.nullableWaitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        statusEmitter: source.controller.stream,
        doAction: () => false,
      );

      expect(status, isNull);
    });

    test("stops listening to the stream once it has answered", () async {
      await WaitUtility.nullableWaitForStatus<String>(
        isExpectedStatus: (status) => status == "ready",
        statusEmitter: source.controller.stream,
        doAction: () {
          source.emit("ready");
          return true;
        },
      );

      expect(source.controller.hasListener, isFalse);
    });
  });
}
