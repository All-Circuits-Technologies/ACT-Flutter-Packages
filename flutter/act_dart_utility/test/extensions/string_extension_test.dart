// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActCommonFormsStringChecks.isValidEmail", () {
    test("accepts a valid address", () {
      expect("someone@example.com".isValidEmail, isTrue);
    });

    test("rejects an invalid address", () {
      expect("someone.example.com".isValidEmail, isFalse);
    });
  });

  group("ActCommonFormsStringChecks.toCapitalized", () {
    test("puts the first letter in upper case and the rest in lower case", () {
      expect("HELLO WORLD".toCapitalized(), "Hello world");
    });

    test("returns an empty string for an empty one", () {
      expect("".toCapitalized(), "");
    });
  });

  group("ActCommonFormsStringChecks.toTitleCase", () {
    test("capitalizes every word", () {
      expect("hello world".toTitleCase(), "Hello World");
    });
  });

  group("ActCommonFormsStringChecks.splitWithoutEmpty", () {
    test("drops the empty elements of the split", () {
      expect("a,,b".splitWithoutEmpty(","), ["a", "b"]);
    });
  });

  group("ActCommonFormsStringChecks.fromAsciiToHex", () {
    test("converts every character to two hexadecimal digits", () {
      expect("AB".fromAsciiToHex(), "4142");
    });
  });

  group("ActCommonFormsStringChecks.fromUtf16ToHex", () {
    test("converts every character to four hexadecimal digits", () {
      expect("AB".fromUtf16ToHex(), "00410042");
    });
  });
}
