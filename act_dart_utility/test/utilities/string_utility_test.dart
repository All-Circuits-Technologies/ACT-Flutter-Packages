// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StringUtility.formatMacAddress", () {
    test("pads every byte which holds a single digit", () {
      expect(
        StringUtility.formatMacAddress(macAddress: "0:1:20:a:bb:CC"),
        "00:01:20:0a:bb:CC",
      );
    });

    test("leaves an already formatted address untouched", () {
      expect(
        StringUtility.formatMacAddress(macAddress: "00:01:20:0A:BB:CC"),
        "00:01:20:0A:BB:CC",
      );
    });

    test("does not change the case of the address", () {
      expect(StringUtility.formatMacAddress(macAddress: "a:B"), "0a:0B");
    });
  });

  group("StringUtility.toCapitalized", () {
    test("puts the first letter in upper case and the rest in lower case", () {
      expect(StringUtility.toCapitalized(string: "hello world"), "Hello world");
      expect(StringUtility.toCapitalized(string: "HELLO WORLD"), "Hello world");
    });

    test("returns an empty string for an empty one", () {
      expect(StringUtility.toCapitalized(string: ""), "");
    });

    test("handles a string of a single letter", () {
      expect(StringUtility.toCapitalized(string: "a"), "A");
    });
  });

  group("StringUtility.toTitleCase", () {
    test("capitalizes every word", () {
      expect(StringUtility.toTitleCase(string: "hello world"), "Hello World");
      expect(StringUtility.toTitleCase(string: "HELLO WORLD"), "Hello World");
    });

    test("keeps the spaces of the string", () {
      expect(StringUtility.toTitleCase(string: "hello  world"), "Hello  World");
    });

    test("returns an empty string for an empty one", () {
      expect(StringUtility.toTitleCase(string: ""), "");
    });
  });

  group("StringUtility.isValidEmail", () {
    test("accepts an address with one at sign and no space", () {
      expect(StringUtility.isValidEmail("someone@example.com"), isTrue);
    });

    test("rejects an address without any at sign", () {
      expect(StringUtility.isValidEmail("someone.example.com"), isFalse);
    });

    test("rejects an address with several at signs", () {
      expect(StringUtility.isValidEmail("someone@example@com"), isFalse);
    });

    test("rejects an address which holds a space", () {
      expect(StringUtility.isValidEmail("some one@example.com"), isFalse);
    });

    test("rejects an address which is not trimmed", () {
      expect(StringUtility.isValidEmail(" someone@example.com "), isFalse);
    });

    test("rejects an empty address", () {
      expect(StringUtility.isValidEmail(""), isFalse);
    });

    test("rejects an address with an empty local part or an empty domain", () {
      expect(StringUtility.isValidEmail("@example.com"), isFalse);
      expect(StringUtility.isValidEmail("someone@"), isFalse);
    });
  });

  group("StringUtility.isValidIpv4", () {
    test("accepts an address made of four bytes", () {
      expect(StringUtility.isValidIpv4("192.168.1.1"), isTrue);
      expect(StringUtility.isValidIpv4("0.0.0.0"), isTrue);
      expect(StringUtility.isValidIpv4("255.255.255.255"), isTrue);
    });

    test("rejects an address with a part above 255", () {
      expect(StringUtility.isValidIpv4("192.168.1.256"), isFalse);
    });

    test("rejects an address with the wrong number of parts", () {
      expect(StringUtility.isValidIpv4("192.168.1"), isFalse);
      expect(StringUtility.isValidIpv4("192.168.1.1.1"), isFalse);
    });

    test("rejects an address which is not made of digits", () {
      expect(StringUtility.isValidIpv4("192.168.1.a"), isFalse);
    });

    test("rejects an empty address", () {
      expect(StringUtility.isValidIpv4(""), isFalse);
    });
  });

  group("StringUtility.parseStrValue", () {
    test("parses the supported types", () {
      expect(StringUtility.parseStrValue<int>("42"), 42);
      expect(StringUtility.parseStrValue<double>("4.2"), 4.2);
      expect(StringUtility.parseStrValue<String>("a value"), "a value");
      expect(StringUtility.parseStrValue<bool>("true"), isTrue);
    });

    test("returns null when the value is null", () {
      expect(StringUtility.parseStrValue<int>(null), isNull);
    });

    test("returns null when the value cannot be parsed", () {
      expect(StringUtility.parseStrValue<int>("forty two"), isNull);
      expect(StringUtility.parseStrValue<bool>("yes"), isNull);
    });

    test("throws on a type which is not supported", () {
      expect(() => StringUtility.parseStrValue<Duration>("42"), throwsA(isA<ActError>()));
    });
  });

  group("StringUtility.castToString", () {
    test("casts the supported types", () {
      expect(StringUtility.castToString<int>(42), (isOk: true, value: "42"));
      expect(StringUtility.castToString<double>(4.2), (isOk: true, value: "4.2"));
      expect(StringUtility.castToString<String>("a value"), (isOk: true, value: "a value"));
      expect(StringUtility.castToString<bool>(true), (isOk: true, value: "true"));
    });

    test("succeeds without any value when the value is null", () {
      expect(StringUtility.castToString<int>(null), (isOk: true, value: null));
    });

    test("fails on a type which is not supported", () {
      expect(
        StringUtility.castToString<Duration>(const Duration(seconds: 1)),
        (isOk: false, value: null),
      );
    });
  });

  group("StringUtility.splitWithoutEmpty", () {
    test("drops the empty elements of the split", () {
      expect(StringUtility.splitWithoutEmpty("a,,b,c", ","), ["a", "b", "c"]);
    });

    test("drops the empty elements at both ends", () {
      expect(StringUtility.splitWithoutEmpty(",a,b,", ","), ["a", "b"]);
    });

    test("returns an empty list when the string only holds separators", () {
      expect(StringUtility.splitWithoutEmpty(",,,", ","), isEmpty);
    });

    test("returns an empty list for an empty string", () {
      expect(StringUtility.splitWithoutEmpty("", ","), isEmpty);
    });

    test("accepts a pattern which is a regular expression", () {
      expect(StringUtility.splitWithoutEmpty("a1b22c", RegExp(r"\d+")), ["a", "b", "c"]);
    });
  });

  group("StringUtility.fromAsciiToHex", () {
    test("converts every character to two hexadecimal digits", () {
      expect(StringUtility.fromAsciiToHex("AB"), "4142");
    });

    test("pads the characters whose code holds a single digit", () {
      expect(StringUtility.fromAsciiToHex("\n"), "0a");
    });

    test("returns an empty string for an empty one", () {
      expect(StringUtility.fromAsciiToHex(""), "");
    });
  });

  group("StringUtility.fromUtf16ToHex", () {
    test("converts every character to four hexadecimal digits", () {
      expect(StringUtility.fromUtf16ToHex("AB"), "00410042");
    });

    test("returns an empty string for an empty one", () {
      expect(StringUtility.fromUtf16ToHex(""), "");
    });
  });
}
