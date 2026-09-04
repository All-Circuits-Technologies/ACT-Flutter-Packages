// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A caller whose type name is used to build the message of the error.
class _Caller {}

void main() {
  group("ActMethodNotImplementedError", () {
    test("names the type of the caller and the missing method", () {
      final error = ActMethodNotImplementedError(caller: _Caller(), method: "doSomething");

      expect(error.message, "_Caller does not implement doSomething");
    });

    test("uses the runtime type of the caller and not its static type", () {
      final Object caller = _Caller();

      final error = ActMethodNotImplementedError(caller: caller, method: "doSomething");

      expect(error.message, "_Caller does not implement doSomething");
    });

    test("is an ACT error", () {
      final error = ActMethodNotImplementedError(caller: _Caller(), method: "doSomething");

      expect(error, isA<ActError>());
    });
  });

  group("ActMethodNotImplementedError.crash", () {
    test("throws and never returns", () {
      // The assertions are enabled when the tests are run, so the trap fires the assertion it
      // guards the release behaviour with, and the error itself is only thrown once they are
      // disabled.
      expect(
        () => ActMethodNotImplementedError.crash(caller: _Caller(), method: "doSomething"),
        throwsAssertionError,
      );
    });

    test("reports the type of the caller and the missing method", () {
      expect(
        () => ActMethodNotImplementedError.crash(caller: _Caller(), method: "doSomething"),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            "message",
            "_Caller does not implement doSomething",
          ),
        ),
      );
    });
  });
}
