// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActMissingConfigException", () {
    test("names the missing configuration value", () {
      final exception = ActMissingConfigException("serverUrl");

      expect(
        exception.message,
        "The configuration value: serverUrl, is missing or hasn't been given",
      );
    });

    test("is an ACT exception", () {
      final exception = ActMissingConfigException("serverUrl");

      expect(exception, isA<ActException>());
    });

    test("returns the message when it is converted to a string", () {
      final exception = ActMissingConfigException("serverUrl");

      expect(exception.toString(), exception.message);
    });
  });
}
