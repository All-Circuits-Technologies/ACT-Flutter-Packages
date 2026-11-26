// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HttpMethods.stringValue", () {
    test("returns the method in upper case", () {
      expect(HttpMethods.get.stringValue, "GET");
      expect(HttpMethods.post.stringValue, "POST");
      expect(HttpMethods.patch.stringValue, "PATCH");
    });

    test("gives a distinct value to every method", () {
      final values = HttpMethods.values.map((method) => method.stringValue).toSet();

      expect(values.length, HttpMethods.values.length);
    });
  });

  group("HttpMethods.isSafe", () {
    test("marks the methods which do not change the server as safe", () {
      expect(HttpMethods.get.isSafe, isTrue);
      expect(HttpMethods.head.isSafe, isTrue);
      expect(HttpMethods.options.isSafe, isTrue);
      expect(HttpMethods.trace.isSafe, isTrue);
    });

    test("marks the methods which change the server as unsafe", () {
      expect(HttpMethods.post.isSafe, isFalse);
      expect(HttpMethods.put.isSafe, isFalse);
      expect(HttpMethods.patch.isSafe, isFalse);
      expect(HttpMethods.delete.isSafe, isFalse);
      expect(HttpMethods.connect.isSafe, isFalse);
    });
  });

  group("HttpMethods.parseFromValue", () {
    test("finds the method named by the value", () {
      expect(HttpMethods.parseFromValue("POST"), HttpMethods.post);
    });

    test("ignores the case of the value", () {
      expect(HttpMethods.parseFromValue("post"), HttpMethods.post);
    });

    test("returns null when the value names no method", () {
      expect(HttpMethods.parseFromValue("FETCH"), isNull);
    });

    test("returns null when the value is null", () {
      expect(HttpMethods.parseFromValue(null), isNull);
    });

    test("reads back the value of every method", () {
      for (final method in HttpMethods.values) {
        expect(HttpMethods.parseFromValue(method.stringValue), method);
      }
    });
  });
}
