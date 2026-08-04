// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/src/act_tb_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_thingsboard.dart';

/// The key the client of the server keeps the token of the user under.
const _tokenKey = "jwt_token";

/// The key the client of the server keeps the token which refreshes the other one under.
const _refreshTokenKey = "refresh_token";

/// The tokens of a user who is signed in.
const _tokens = AuthTokens(
  accessToken: AuthToken(raw: "a token"),
  refreshToken: AuthToken(raw: "a refresh token"),
);

void main() {
  late FakeTbAuthStorageService storage;

  setUp(() => storage = FakeTbAuthStorageService());

  /// The storage the client of the server reads and writes its tokens through.
  ///
  /// It reaches the storage of the application, unless [withoutService] says that the application
  /// has none.
  ActTbStorage aStorage({bool withoutService = false}) =>
      ActTbStorage(storageServiceGetter: withoutService ? null : () => storage);

  group("ActTbStorage.getItem", () {
    test("answers the token of the user", () async {
      storage.storedTokens = _tokens;

      expect(await aStorage().getItem(_tokenKey), "a token");
    });

    test("answers the token which refreshes the other one", () async {
      storage.storedTokens = _tokens;

      expect(await aStorage().getItem(_refreshTokenKey), "a refresh token");
    });

    test("answers the default value of a key it knows nothing about", () async {
      storage.storedTokens = _tokens;

      expect(await aStorage().getItem("another key", defaultValue: "a default"), "a default");
    });

    test("answers the default value when no user is signed in", () async {
      expect(await aStorage().getItem(_tokenKey, defaultValue: "a default"), "a default");
    });

    test("answers the default value when the application keeps no token", () async {
      expect(
        await aStorage(withoutService: true).getItem(_tokenKey, defaultValue: "a default"),
        "a default",
      );
    });
  });

  group("ActTbStorage.containsKey", () {
    test("says that the token of a signed in user is there", () async {
      storage.storedTokens = _tokens;

      expect(await aStorage().containsKey(_tokenKey), isTrue);
    });

    test("says that the token of a user who is not signed in is not there", () async {
      expect(await aStorage().containsKey(_tokenKey), isFalse);
    });

    test("says that a key it knows nothing about is not there", () async {
      storage.storedTokens = _tokens;

      expect(await aStorage().containsKey("another key"), isFalse);
    });
  });

  group("ActTbStorage.setItem", () {
    test("keeps the token of the user", () async {
      await aStorage().setItem(_tokenKey, "a new token");

      expect(storage.storedTokens?.accessToken, const AuthToken(raw: "a new token"));
    });

    test("keeps the token which refreshes the other one", () async {
      await aStorage().setItem(_refreshTokenKey, "a new refresh token");

      expect(storage.storedTokens?.refreshToken, const AuthToken(raw: "a new refresh token"));
    });

    test("leaves the other token as it was", () async {
      storage.storedTokens = _tokens;

      await aStorage().setItem(_tokenKey, "a new token");

      expect(storage.storedTokens?.refreshToken, const AuthToken(raw: "a refresh token"));
    });

    test("keeps nothing of a key it knows nothing about", () async {
      await aStorage().setItem("another key", "a value");

      expect(storage.storedTokens, isNull);
    });

    test("keeps nothing when the application keeps no token", () async {
      await aStorage(withoutService: true).setItem(_tokenKey, "a new token");

      expect(storage.storedTokens, isNull);
      expect(storage.calls, isEmpty);
    });
  });

  group("ActTbStorage.deleteItem", () {
    test("forgets the token of the user", () async {
      storage.storedTokens = _tokens;

      await aStorage().deleteItem(_tokenKey);

      expect(storage.storedTokens?.accessToken, isNull);
    });

    test("keeps the token which refreshes the one it forgets", () async {
      storage.storedTokens = _tokens;

      await aStorage().deleteItem(_tokenKey);

      expect(storage.storedTokens?.refreshToken, const AuthToken(raw: "a refresh token"));
    });

    test("forgets the token which refreshes the other one", () async {
      storage.storedTokens = _tokens;

      await aStorage().deleteItem(_refreshTokenKey);

      expect(storage.storedTokens?.refreshToken, isNull);
      expect(storage.storedTokens?.accessToken, const AuthToken(raw: "a token"));
    });

    test("forgets nothing of a key it knows nothing about", () async {
      storage.storedTokens = _tokens;

      await aStorage().deleteItem("another key");

      expect(storage.storedTokens, _tokens);
    });

    test("does nothing when no user is signed in", () async {
      await aStorage().deleteItem(_tokenKey);

      expect(storage.storedTokens, isNull);
      expect(storage.calls, ["loadTokens()"]);
    });
  });
}
