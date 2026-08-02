// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a value through a getter which may be synchronous or asynchronous.
Future<int> _read(ActValueGetter<int> getter) async => getter();

/// Runs a callback which may be synchronous or asynchronous.
Future<void> _run(ActCallback callback) async => callback();

void main() {
  group("ActValueGetter", () {
    test("accepts a getter which answers at once", () async {
      expect(await _read(() => 42), 42);
    });

    test("accepts a getter which answers later", () async {
      expect(await _read(() async => 42), 42);
    });
  });

  group("ActCallback", () {
    test("accepts a callback which returns at once", () async {
      var called = false;

      await _run(() => called = true);

      expect(called, isTrue);
    });

    test("accepts a callback which returns later", () async {
      var called = false;

      await _run(() async => called = true);

      expect(called, isTrue);
    });
  });
}
