// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActUnsupportedTypeError", () {
    test("names the unsupported type when no context is given", () {
      final error = ActUnsupportedTypeError<Duration>();

      expect(error.message, "The type: Duration, isn't supported");
    });

    test("appends the context to the message when one is given", () {
      final error = ActUnsupportedTypeError<Duration>(context: "while parsing the configuration");

      expect(
        error.message,
        "The type: Duration, isn't supported, context: while parsing the configuration",
      );
    });

    test("keeps the context available on the error", () {
      final error = ActUnsupportedTypeError<Duration>(context: "while parsing the configuration");

      expect(error.context, "while parsing the configuration");
    });

    test("has no context when none is given", () {
      final error = ActUnsupportedTypeError<Duration>();

      expect(error.context, isNull);
    });

    test("is an ACT error", () {
      final error = ActUnsupportedTypeError<Duration>();

      expect(error, isA<ActError>());
    });
  });
}
