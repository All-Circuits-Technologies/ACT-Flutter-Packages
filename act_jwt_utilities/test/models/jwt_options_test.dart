// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("JwtOptions", () {
    test("carries no claim unless the caller gives one", () {
      const options = JwtOptions(algorithm: JWTAlgorithm.HS256);

      expect(options.audience, isNull);
      expect(options.issuer, isNull);
      expect(options.subject, isNull);
      expect(options.expirationTime, isNull);
      expect(options.notBefore, isNull);
    });

    test("equals other options which carry the same claims", () {
      expect(
        const JwtOptions(
          algorithm: JWTAlgorithm.HS256,
          issuer: "an issuer",
          expirationTime: Duration(hours: 1),
        ),
        const JwtOptions(
          algorithm: JWTAlgorithm.HS256,
          issuer: "an issuer",
          expirationTime: Duration(hours: 1),
        ),
      );
    });

    test("differs from options which carry another algorithm", () {
      expect(
        const JwtOptions(algorithm: JWTAlgorithm.HS256),
        isNot(const JwtOptions(algorithm: JWTAlgorithm.HS512)),
      );
    });

    test("differs from options which carry another expiration time", () {
      expect(
        const JwtOptions(algorithm: JWTAlgorithm.HS256, expirationTime: Duration(hours: 1)),
        isNot(
          const JwtOptions(algorithm: JWTAlgorithm.HS256, expirationTime: Duration(hours: 2)),
        ),
      );
    });
  });
}
