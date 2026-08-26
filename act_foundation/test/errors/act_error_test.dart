// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal concrete error, to exercise the behaviour [ActError] gives to its derived classes.
class _TestError extends ActError {
  _TestError(super.message);
}

void main() {
  group("ActError", () {
    test("keeps the message given to the constructor", () {
      final error = _TestError("something went wrong");

      expect(error.message, "something went wrong");
    });

    test("is an error and not an exception", () {
      final error = _TestError("something went wrong");

      expect(error, isA<Error>());
      expect(error, isNot(isA<Exception>()));
    });

    test("can be thrown and caught as an error", () {
      expect(() => throw _TestError("something went wrong"), throwsA(isA<ActError>()));
    });
  });

  group("ActError.toString", () {
    test("returns the message alone", () {
      final error = _TestError("something went wrong");

      expect(error.toString(), "something went wrong");
    });

    test("returns an empty string when the message is empty", () {
      final error = _TestError("");

      expect(error.toString(), "");
    });
  });
}
