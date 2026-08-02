// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The token an application shows a server to prove who the user is.
const _accessToken = AuthToken(raw: "an access token");

/// The token an application asks a new access token with.
const _refreshToken = AuthToken(raw: "a refresh token");

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("AuthTokens.copyWith", () {
    const tokens = AuthTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
      idToken: "an id token",
    );

    test("keeps the values the caller did not give", () {
      expect(tokens.copyWith(), tokens);
    });

    test("replaces the values the caller gave", () {
      const other = AuthToken(raw: "another access token");

      final copy = tokens.copyWith(accessToken: other, idToken: "another id token");

      expect(copy.accessToken, other);
      expect(copy.idToken, "another id token");
      expect(copy.refreshToken, _refreshToken);
    });

    test("drops the tokens the caller asks to drop", () {
      final copy = tokens.copyWith(
        forceAccessTokenValue: true,
        forceRefreshTokenValue: true,
        forceIdTokenValue: true,
      );

      expect(copy, const AuthTokens());
    });
  });

  group("AuthTokens.toJson", () {
    test("writes the tokens it holds", () {
      const tokens = AuthTokens(
        accessToken: _accessToken,
        refreshToken: _refreshToken,
        idToken: "an id token",
      );

      expect(tokens.toJson(), {
        "accessToken": _accessToken.toJson(),
        "refreshToken": _refreshToken.toJson(),
        "idToken": "an id token",
      });
    });

    test("writes nothing of the tokens it does not hold", () {
      expect(const AuthTokens().toJson(), isEmpty);
    });
  });

  group("AuthTokens.fromJson", () {
    test("reads back the tokens it wrote", () {
      const tokens = AuthTokens(
        accessToken: _accessToken,
        refreshToken: _refreshToken,
        idToken: "an id token",
      );

      expect(AuthTokens.fromJson(tokens.toJson()), tokens);
    });

    test("reads a json which holds no token at all", () {
      expect(AuthTokens.fromJson(const {}), const AuthTokens());
    });

    test("reads nothing from a json whose access token cannot be read", () {
      expect(AuthTokens.fromJson(const {"accessToken": <String, dynamic>{}}), isNull);
    });

    test("reads nothing from a json whose id token is not a text", () {
      expect(AuthTokens.fromJson(const {"idToken": 42}), isNull);
    });

    test("warns about the json it could not read", () {
      AuthTokens.fromJson(const {"idToken": 42});

      expect(logger.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });
  });
}
