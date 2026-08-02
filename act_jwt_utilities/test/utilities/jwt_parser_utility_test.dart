// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key the tokens of the tests are signed with.
final _key = SecretKey("a secret which is long enough for the algorithm");

/// Signs a token which carries [payload].
String _sign(Map<String, dynamic> payload) => JWT(payload).sign(_key);

/// Signs a token which expires at [expiration], given in seconds since the epoch.
String _signExpiringAt(DateTime expiration) =>
    _sign({"exp": expiration.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond});

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("JwtParserUtility.tryToParseToken", () {
    test("returns the token it decodes", () {
      final jwt = JwtParserUtility.tryToParseToken(_sign({"sub": "a user"}));

      expect((jwt?.payload as Map?)?["sub"], "a user");
    });

    test("decodes a token without verifying its signature", () {
      final token = _sign({"sub": "a user"});
      final tampered = "${token.substring(0, token.lastIndexOf(".") + 1)}notASignature";

      expect(JwtParserUtility.tryToParseToken(tampered), isNotNull);
    });

    test("returns null for a string which is not a token", () {
      expect(JwtParserUtility.tryToParseToken("not a token"), isNull);
    });

    test("warns about the string it cannot decode", () {
      JwtParserUtility.tryToParseToken("not a token");

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("JwtParserUtility.getExpiration", () {
    test("returns the expiration the token carries in seconds", () {
      final expiration = DateTime.utc(2030, 5, 17, 10, 30);
      final jwt = JWT.decode(_signExpiringAt(expiration));

      expect(JwtParserUtility.getExpiration(jwt: jwt), (isOk: true, exp: expiration));
    });

    test("returns the expiration the token carries in milliseconds when asked to", () {
      final expiration = DateTime.utc(2030, 5, 17, 10, 30);
      final jwt = JWT.decode(_sign({"exp": expiration.millisecondsSinceEpoch}));

      expect(
        JwtParserUtility.getExpiration(jwt: jwt, isTsInSeconds: false),
        (isOk: true, exp: expiration),
      );
    });

    test("accepts a token which carries no expiration", () {
      final jwt = JWT.decode(_sign({"sub": "a user"}));

      expect(JwtParserUtility.getExpiration(jwt: jwt), (isOk: true, exp: null));
    });

    test("refuses a token whose expiration is not a number", () {
      final jwt = JWT.decode(_sign({"exp": "tomorrow"}));

      expect(JwtParserUtility.getExpiration(jwt: jwt), (isOk: false, exp: null));
    });

    test("refuses a token whose payload is not a map", () {
      final jwt = JWT.decode(JWT("a payload which is not a map").sign(_key));

      expect(JwtParserUtility.getExpiration(jwt: jwt), (isOk: false, exp: null));
    });

    test("warns about the token it refuses", () {
      final jwt = JWT.decode(_sign({"exp": "tomorrow"}));

      JwtParserUtility.getExpiration(jwt: jwt);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("JwtParserUtility.isTokenValid", () {
    test("returns true for a token which has not expired yet", () {
      final jwt = JWT.decode(_signExpiringAt(DateTime.now().toUtc().add(const Duration(days: 1))));

      expect(JwtParserUtility.isTokenValid(jwt), isTrue);
    });

    test("returns false for a token which has expired", () {
      final jwt = JWT.decode(
        _signExpiringAt(DateTime.now().toUtc().subtract(const Duration(days: 1))),
      );

      expect(JwtParserUtility.isTokenValid(jwt), isFalse);
    });

    test("returns true for a token which carries no expiration", () {
      final jwt = JWT.decode(_sign({"sub": "a user"}));

      expect(JwtParserUtility.isTokenValid(jwt), isTrue);
    });

    test("returns false when the expiration cannot be read", () {
      final jwt = JWT.decode(_sign({"exp": "tomorrow"}));

      expect(JwtParserUtility.isTokenValid(jwt), isFalse);
    });

    test("reads the expiration in milliseconds when asked to", () {
      final expiration = DateTime.now().toUtc().add(const Duration(days: 1));
      final jwt = JWT.decode(_sign({"exp": expiration.millisecondsSinceEpoch}));

      expect(JwtParserUtility.isTokenValid(jwt, isTsInSeconds: false), isTrue);
    });
  });

  group("JwtParserUtility.isTokenFromStringValid", () {
    test("returns true for a token which has not expired yet", () {
      final token = _signExpiringAt(DateTime.now().toUtc().add(const Duration(days: 1)));

      expect(JwtParserUtility.isTokenFromStringValid(token), isTrue);
    });

    test("returns false for a token which has expired", () {
      final token = _signExpiringAt(DateTime.now().toUtc().subtract(const Duration(days: 1)));

      expect(JwtParserUtility.isTokenFromStringValid(token), isFalse);
    });

    test("returns false when there is no token", () {
      expect(JwtParserUtility.isTokenFromStringValid(null), isFalse);
    });

    test("returns false for a string which is not a token", () {
      expect(JwtParserUtility.isTokenFromStringValid("not a token"), isFalse);
    });

    test("warns about nothing when there is no token to read", () {
      JwtParserUtility.isTokenFromStringValid(null);

      expect(logger.records, isEmpty);
    });
  });

  group("JwtParserUtility.getExpirationFromString", () {
    test("returns the expiration the token carries", () {
      final expiration = DateTime.utc(2030, 5, 17, 10, 30);

      expect(
        JwtParserUtility.getExpirationFromString(_signExpiringAt(expiration)),
        (isOk: true, exp: expiration),
      );
    });

    test("refuses a string which is not a token", () {
      expect(
        JwtParserUtility.getExpirationFromString("not a token"),
        (isOk: false, exp: null),
      );
    });
  });

  group("JwtParserUtility.extractJwtFromHeaderValue", () {
    test("returns the token which follows the bearer key", () {
      expect(
        JwtParserUtility.extractJwtFromHeaderValue(
          headerValue: "Bearer aToken",
          bearerKey: "Bearer",
        ),
        "aToken",
      );
    });

    test("returns null when the value does not start with the bearer key", () {
      expect(
        JwtParserUtility.extractJwtFromHeaderValue(
          headerValue: "Basic aToken",
          bearerKey: "Bearer",
        ),
        isNull,
      );
    });

    test("returns null when the value carries no token", () {
      expect(
        JwtParserUtility.extractJwtFromHeaderValue(headerValue: "Bearer", bearerKey: "Bearer"),
        isNull,
      );
    });

    test("returns null when the value carries more than a key and a token", () {
      expect(
        JwtParserUtility.extractJwtFromHeaderValue(
          headerValue: "Bearer aToken and more",
          bearerKey: "Bearer",
        ),
        isNull,
      );
    });
  });
}
