// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A singleton class, only used for the name it gives to the message of the error.
class _Manager {}

void main() {
  group("ActSingletonNotCreatedError", () {
    test("names the type of the singleton", () {
      final error = ActSingletonNotCreatedError<_Manager>();

      expect(
        error.message,
        "The singleton: _Manager, hadn't been created before we tried to access singleton instance",
      );
    });

    test("is an ACT error", () {
      final error = ActSingletonNotCreatedError<_Manager>();

      expect(error, isA<ActError>());
    });

    test("distinguishes the errors raised for two different singletons", () {
      final error = ActSingletonNotCreatedError<_Manager>();
      final otherError = ActSingletonNotCreatedError<String>();

      expect(error.message, isNot(otherError.message));
    });
  });
}
