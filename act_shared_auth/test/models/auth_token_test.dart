// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key the tokens of the tests are signed with.
final _key = SecretKey("a secret which is long enough for the algorithm");

/// Signs a token which carries [payload].
String _sign(Map<String, dynamic> payload) => JWT(payload).sign(_key);

/// A moment which is behind whatever the tests run.
final _past = DateTime.utc(2020);

/// A moment which is ahead of whatever the tests run.
final _future = DateTime.utc(2100);

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("AuthToken.isValid", () {
    test("holds a token which never expires for valid", () {
      expect(const AuthToken(raw: "a token").isValid(), isTrue);
    });

    test("holds a token which expires later for valid", () {
      expect(AuthToken(raw: "a token", expiration: _future).isValid(), isTrue);
    });

    test("holds a token which has expired for invalid", () {
      expect(AuthToken(raw: "a token", expiration: _past).isValid(), isFalse);
    });

    test("holds a token which carries nothing for invalid", () {
      expect(const AuthToken(raw: "").isValid(), isFalse);
    });

    test("ignores the expiration when the caller asks it to", () {
      final token = AuthToken(raw: "a token", expiration: _past);

      expect(token.isValid(testExpiration: false), isTrue);
    });

    test("holds a token which carries nothing for invalid, whatever its expiration", () {
      expect(const AuthToken(raw: "").isValid(testExpiration: false), isFalse);
    });
  });

  group("AuthToken.copyWith", () {
    test("keeps the values the caller did not give", () {
      final token = AuthToken(raw: "a token", expiration: _future);

      expect(token.copyWith(), token);
    });

    test("replaces the values the caller gave", () {
      final token = AuthToken(raw: "a token", expiration: _future);

      final copy = token.copyWith(raw: "another token", expiration: _past);

      expect(copy, AuthToken(raw: "another token", expiration: _past));
    });

    test("drops the expiration when the caller asks for it", () {
      final token = AuthToken(raw: "a token", expiration: _future);

      expect(token.copyWith(forceExpirationValue: true).expiration, isNull);
    });
  });

  group("AuthToken.toJson", () {
    test("writes the token and its expiration", () {
      final token = AuthToken(raw: "a token", expiration: _future);

      expect(token.toJson(), {"raw": "a token", "expiration": _future.millisecondsSinceEpoch});
    });

    test("writes no expiration for a token which never expires", () {
      expect(const AuthToken(raw: "a token").toJson(), {"raw": "a token"});
    });
  });

  group("AuthToken.fromJson", () {
    test("reads back the token it wrote", () {
      final token = AuthToken(raw: "a token", expiration: _future);

      expect(AuthToken.fromJson(token.toJson()), token);
    });

    test("reads a token which never expires", () {
      expect(AuthToken.fromJson(const {"raw": "a token"}), const AuthToken(raw: "a token"));
    });

    test("reads nothing from a json which carries no token", () {
      expect(AuthToken.fromJson(const {}), isNull);
    });

    test("reads nothing from a json whose expiration is not a moment", () {
      expect(AuthToken.fromJson(const {"raw": "a token", "expiration": "tomorrow"}), isNull);
    });

    test("warns about the json it could not read", () {
      AuthToken.fromJson(const {});

      expect(logger.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });
  });

  group("AuthToken.fromJwtToken", () {
    test("reads the expiration the token carries", () {
      final raw = _sign({"exp": _future.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond});

      expect(AuthToken.fromJwtToken(raw), AuthToken(raw: raw, expiration: _future));
    });

    test("reads a token which never expires", () {
      final raw = _sign({"sub": "a user"});

      expect(AuthToken.fromJwtToken(raw), AuthToken(raw: raw));
    });

    test("reads nothing from a string which is not a token", () {
      expect(AuthToken.fromJwtToken("not a token"), isNull);
    });
  });
}
