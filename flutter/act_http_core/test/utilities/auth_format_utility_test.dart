// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthFormatUtility.formatBasicAuthentication", () {
    test("returns the authorization header key", () {
      final header = AuthFormatUtility.formatBasicAuthentication(
        username: "someone",
        password: "a secret",
      );

      expect(header.key, HeaderConstants.authorizationHeaderKey);
    });

    test("encodes the credentials as the basic scheme asks for", () {
      final header = AuthFormatUtility.formatBasicAuthentication(
        username: "someone",
        password: "a secret",
      );

      expect(header.value, "Basic ${base64Encode("someone:a secret".codeUnits)}");
    });

    test("separates the username and the password with a colon", () {
      final header = AuthFormatUtility.formatBasicAuthentication(
        username: "someone",
        password: "a secret",
      );
      final encoded = header.value.substring(HeaderConstants.authBasicKey.length + 1);

      expect(String.fromCharCodes(base64Decode(encoded)), "someone:a secret");
    });

    test("accepts empty credentials", () {
      final header = AuthFormatUtility.formatBasicAuthentication(username: "", password: "");

      expect(header.value, "Basic ${base64Encode(":".codeUnits)}");
    });

    test("leaves no placeholder in the header value", () {
      final header = AuthFormatUtility.formatBasicAuthentication(
        username: "someone",
        password: "a secret",
      );

      expect(header.value.contains(HeaderConstants.credsBasicKey), isFalse);
    });
  });
}
