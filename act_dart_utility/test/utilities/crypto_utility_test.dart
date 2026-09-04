// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

final _alphaNumeric = RegExp(r"^[A-Za-z0-9]*$");
final _alphaNumericAndSpecial = RegExp(r"^[A-Za-z0-9!@#$%^*]*$");

void main() {
  group("CryptoUtility.getRandomString", () {
    test("returns a string of the asked length", () {
      expect(CryptoUtility.getRandomString(32).length, 32);
    });

    test("returns an empty string for a length of zero", () {
      expect(CryptoUtility.getRandomString(0), isEmpty);
    });

    test("only uses alphanumeric characters by default", () {
      expect(CryptoUtility.getRandomString(256), matches(_alphaNumeric));
    });

    test("may use special characters when it is asked to", () {
      expect(
        CryptoUtility.getRandomString(256, addSpecialChars: true),
        matches(_alphaNumericAndSpecial),
      );
    });

    test("returns a different string at every call", () {
      final strings = List.generate(10, (_) => CryptoUtility.getRandomString(32));

      expect(strings.toSet().length, strings.length);
    });
  });
}
