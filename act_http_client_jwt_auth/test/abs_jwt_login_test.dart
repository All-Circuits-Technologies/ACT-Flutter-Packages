// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_jwt_auth/act_http_client_jwt_auth.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_jwt_login.dart';

void main() {
  late FakeServerRequester server;

  setUp(() => server = FakeServerRequester());

  /// The login of an application which signs in with a request of its own.
  ///
  /// The server answers [answered] when the user signs in.
  FakeJwtLogin aLogin({
    AuthTokens? answered,
    bool canBuildLoginRequest = true,
    bool verifyTokenExpirationDate = true,
    String headerAuthKey = "Authorization",
    String headerAuthValueFormatted = "Bearer {token}",
  }) => FakeJwtLogin(
    serverRequester: server,
    loginAnswer: answered,
    canBuildLoginRequest: canBuildLoginRequest,
    verifyTokenExpirationDate: verifyTokenExpirationDate,
    headerAuthKey: headerAuthKey,
    headerAuthValueFormatted: headerAuthValueFormatted,
  );

  group("AbsJwtLogin.manageLogInWithRequest", () {
    test("signs the user in when it holds no token", () async {
      final login = aLogin(answered: AuthTokens(accessToken: aToken()));

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.success);
      expect(server.routes, [aLoginRoute]);
    });

    test("adds the token of the user to the request", () async {
      final login = aLogin(answered: AuthTokens(accessToken: aToken(name: "a raw token")));
      final request = aRequest();

      await login.manageLogInWithRequest(request);

      expect(request.headers["Authorization"], "Bearer a raw token");
    });

    test("adds the token where the application asked for it", () async {
      final login = aLogin(
        answered: AuthTokens(accessToken: aToken(name: "a raw token")),
        headerAuthKey: "X-Token",
        headerAuthValueFormatted: "token={token}",
      );
      final request = aRequest();

      await login.manageLogInWithRequest(request);

      expect(request.headers["X-Token"], "token=a raw token");
    });

    test("signs the user in once and keeps the token for the next requests", () async {
      final login = aLogin(answered: AuthTokens(accessToken: aToken()));

      await login.manageLogInWithRequest(aRequest());
      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });

    test("signs the user in again once the token it holds expired", () async {
      final login = aLogin(
        answered: AuthTokens(accessToken: aToken(validFor: const Duration(seconds: -1))),
      );

      await login.manageLogInWithRequest(aRequest());
      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute, aLoginRoute]);
    });

    test("keeps a token which expired when it is told not to read the expiration", () async {
      final login = aLogin(
        answered: AuthTokens(accessToken: aToken(validFor: const Duration(seconds: -1))),
        verifyTokenExpirationDate: false,
      );

      await login.manageLogInWithRequest(aRequest());
      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });

    test("gives up when it cannot build the request which signs the user in", () async {
      final login = aLogin(canBuildLoginRequest: false);

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.globalError);
      expect(server.requests, isEmpty);
    });

    test("answers what the server answered when the sign in failed", () async {
      final login = aLogin();
      server.answers[aLoginRoute] = RequestStatus.timeoutError;

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.timeoutError);
    });

    test("gives up when the answer of the server holds no token", () async {
      final login = aLogin();

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.globalError);
      expect(login.parsedLogins, 1);
    });

    test("gives up when the token the server answered is not usable", () async {
      final login = aLogin(
        answered: AuthTokens(accessToken: aToken(validFor: const Duration(seconds: -1))),
      );

      expect(await login.manageLogInWithRequest(aRequest()), RequestStatus.globalError);
    });

    test("forgets the token which expired when nothing worked", () async {
      final login = aLogin();
      await login.keep(AuthTokens(accessToken: aToken(validFor: const Duration(seconds: -1))));
      server.answers[aLoginRoute] = RequestStatus.globalError;

      await login.manageLogInWithRequest(aRequest());

      expect(login.tokensInfo, isNull);
    });
  });

  group("AbsJwtLogin.newTokensStream", () {
    test("tells the application about the tokens it got from the server", () async {
      final tokens = AuthTokens(accessToken: aToken());
      final login = aLogin(answered: tokens);
      final answered = <AuthTokens?>[];
      login.newTokensStream.listen(answered.add);

      await login.manageLogInWithRequest(aRequest());
      await pumpEventQueue();

      expect(answered, [tokens]);
    });

    test("says nothing of tokens which are the ones it already holds", () async {
      final login = aLogin(
        answered: AuthTokens(accessToken: aToken(validFor: const Duration(seconds: -1))),
        verifyTokenExpirationDate: false,
      );
      await login.manageLogInWithRequest(aRequest());
      final answered = <AuthTokens?>[];
      login.newTokensStream.listen(answered.add);

      await login.keep(login.tokensInfo!);
      await pumpEventQueue();

      expect(answered, isEmpty);
    });

    test("tells the application when it no longer holds any token", () async {
      final login = aLogin(answered: AuthTokens(accessToken: aToken()));
      await login.manageLogInWithRequest(aRequest());
      final answered = <AuthTokens?>[];
      login.newTokensStream.listen(answered.add);

      await login.clearLogins();
      await pumpEventQueue();

      expect(answered, [null]);
    });

    test("says nothing when it held no token to forget", () async {
      final login = aLogin();
      final answered = <AuthTokens?>[];
      login.newTokensStream.listen(answered.add);

      await login.clearLogins();
      await pumpEventQueue();

      expect(answered, isEmpty);
    });
  });
}
