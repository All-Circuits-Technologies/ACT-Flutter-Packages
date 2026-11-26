// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SignResult", () {
    test("equals another result which carries the same token and the same duration", () {
      expect(
        const SignResult(expirationTime: Duration(hours: 1), jwt: "aToken"),
        const SignResult(expirationTime: Duration(hours: 1), jwt: "aToken"),
      );
    });

    test("differs from a result which carries another token", () {
      expect(
        const SignResult(expirationTime: Duration(hours: 1), jwt: "aToken"),
        isNot(const SignResult(expirationTime: Duration(hours: 1), jwt: "anotherToken")),
      );
    });

    test("differs from a result which carries another duration", () {
      expect(
        const SignResult(expirationTime: Duration(hours: 1), jwt: "aToken"),
        isNot(const SignResult(expirationTime: Duration(hours: 2), jwt: "aToken")),
      );
    });
  });
}
