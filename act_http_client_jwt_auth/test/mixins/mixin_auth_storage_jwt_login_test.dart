// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_jwt_auth/act_http_client_jwt_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_jwt_login.dart';

void main() {
  late FakeServerRequester server;
  late FakeJwtStorageService storage;

  setUp(() {
    server = FakeServerRequester();
    storage = FakeJwtStorageService();
  });

  /// The login of an application which keeps the tokens of its user in a storage.
  ///
  /// The application keeps nothing when [withoutStorage] says so.
  FakeStoredJwtLogin aLogin({AuthTokens? answered, bool withoutStorage = false}) =>
      FakeStoredJwtLogin(
        serverRequester: server,
        storageService: withoutStorage ? null : storage,
        loginAnswer: answered,
      );

  group("MixinAuthStorageJwtLogin.initLogin", () {
    test("takes the tokens the application kept", () async {
      final tokens = AuthTokens(accessToken: aToken());
      storage.storedTokens = tokens;
      final login = aLogin();

      await login.initLogin();

      expect(login.tokensInfo, tokens);
    });

    test("keeps nothing more than what it just read", () async {
      storage.storedTokens = AuthTokens(accessToken: aToken());
      final login = aLogin();

      await login.initLogin();

      expect(storage.calls, ["loadTokens()"]);
    });

    test("takes nothing when the application kept nothing", () async {
      final login = aLogin();

      await login.initLogin();

      expect(login.tokensInfo, isNull);
    });

    test("reads nothing when the application keeps nothing", () async {
      final login = aLogin(withoutStorage: true);

      await login.initLogin();

      expect(storage.calls, isEmpty);
    });
  });

  group("MixinAuthStorageJwtLogin.manageLogInWithRequest", () {
    test("reads the tokens of the application before it uses the ones it holds", () async {
      final login = aLogin();
      await login.initLogin();
      storage.storedTokens = AuthTokens(accessToken: aToken(name: "a token of another view"));

      final request = aRequest();
      await login.manageLogInWithRequest(request);

      expect(request.headers["Authorization"], "Bearer a token of another view");
      expect(server.requests, isEmpty);
    });

    test("keeps the tokens it got from the server", () async {
      final tokens = AuthTokens(accessToken: aToken());
      final login = aLogin(answered: tokens);

      await login.manageLogInWithRequest(aRequest());

      expect(storage.storedTokens, tokens);
    });

    test("signs the user in when the application kept nothing", () async {
      final login = aLogin(answered: AuthTokens(accessToken: aToken()));

      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });
  });

  group("MixinAuthStorageJwtLogin.clearLogins", () {
    test("has the application forget the tokens it kept", () async {
      storage.storedTokens = AuthTokens(accessToken: aToken());
      final login = aLogin();
      await login.initLogin();

      await login.clearLogins();

      expect(storage.storedTokens, isNull);
      expect(login.tokensInfo, isNull);
    });

    test("forgets what it keeps even when it held nothing", () async {
      storage.storedTokens = AuthTokens(accessToken: aToken());
      final login = aLogin();

      await login.clearLogins();

      expect(storage.storedTokens, isNull);
    });
  });
}
