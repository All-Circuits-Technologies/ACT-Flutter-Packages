// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal concrete exception, to exercise the behaviour [ActException] gives to its derived
/// classes.
class _TestException extends ActException {
  const _TestException(super.message);
}

void main() {
  group("ActException", () {
    test("keeps the message given to the constructor", () {
      const exception = _TestException("the value is invalid");

      expect(exception.message, "the value is invalid");
    });

    test("is an exception and not an error", () {
      const exception = _TestException("the value is invalid");

      expect(exception, isA<Exception>());
      expect(exception, isNot(isA<Error>()));
    });

    test("can be thrown and caught as an exception", () {
      expect(() => throw const _TestException("the value is invalid"), throwsA(isA<ActException>()));
    });
  });

  group("ActException.toString", () {
    test("returns the message alone", () {
      const exception = _TestException("the value is invalid");

      expect(exception.toString(), "the value is invalid");
    });

    test("returns an empty string when the message is empty", () {
      const exception = _TestException("");

      expect(exception.toString(), "");
    });
  });
}
