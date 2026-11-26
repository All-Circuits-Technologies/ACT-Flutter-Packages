// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Base64Utility.tryToParse", () {
    test("decodes a base64 value", () {
      final decoded = Base64Utility.tryToParse(base64Encode(utf8.encode("a message")));

      expect(utf8.decode(decoded!), "a message");
    });

    test("ignores the new lines of a wrapped value", () {
      final encoded = base64Encode(utf8.encode("a much longer message to be wrapped"));
      final wrapped = "${encoded.substring(0, 8)}\n${encoded.substring(8)}";

      final decoded = Base64Utility.tryToParse(wrapped);

      expect(utf8.decode(decoded!), "a much longer message to be wrapped");
    });

    test("decodes an empty value to an empty byte list", () {
      expect(Base64Utility.tryToParse(""), isEmpty);
    });

    test("returns null on a value which is not base64", () {
      expect(Base64Utility.tryToParse("not base64 at all!"), isNull);
    });

    test("warns through the logger when the value cannot be decoded", () {
      final logger = FakeLogger();

      Base64Utility.tryToParse("not base64 at all!", logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("logs nothing when the value is decoded", () {
      final logger = FakeLogger();

      Base64Utility.tryToParse(base64Encode(utf8.encode("a message")), logger: logger);

      expect(logger.records, isEmpty);
    });
  });
}
