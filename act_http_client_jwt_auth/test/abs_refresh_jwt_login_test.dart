// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_jwt_auth/act_http_client_jwt_auth.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_jwt_login.dart';

/// The tokens of a user whose token expired but who can still refresh it.
AuthTokens _expiredWithRefresh() => AuthTokens(
  accessToken: aToken(validFor: const Duration(seconds: -1), name: "an old token"),
  refreshToken: aToken(name: "a refresh token"),
);

void main() {
  late FakeServerRequester server;

  setUp(() => server = FakeServerRequester());

  /// The login of an application which refreshes its token rather than signing in again.
  FakeRefreshJwtLogin aLogin({
    AuthTokens? refreshed,
    AuthTokens? signedIn,
    bool canBuildRefreshRequest = true,
  }) => FakeRefreshJwtLogin(
    serverRequester: server,
    refreshAnswer: refreshed,
    loginAnswer: signedIn,
    canBuildRefreshRequest: canBuildRefreshRequest,
  );

  group("AbsRefreshJwtLogin.manageLogInWithRequest", () {
    test("refreshes the token which expired rather than signing the user in", () async {
      final login = aLogin(refreshed: AuthTokens(accessToken: aToken(name: "a new token")));
      await login.keep(_expiredWithRefresh());

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.success);
      expect(server.routes, [aRefreshRoute]);
    });

    test("adds the token it got from the refresh to the request", () async {
      final login = aLogin(refreshed: AuthTokens(accessToken: aToken(name: "a new token")));
      await login.keep(_expiredWithRefresh());
      final request = aRequest();

      await login.manageLogInWithRequest(request);

      expect(request.headers["Authorization"], "Bearer a new token");
    });

    test("signs the user in when it holds nothing to refresh", () async {
      final login = aLogin(signedIn: AuthTokens(accessToken: aToken()));

      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });

    test("signs the user in when the token which refreshes the other one expired", () async {
      final login = aLogin(signedIn: AuthTokens(accessToken: aToken()));
      await login.keep(
        AuthTokens(
          accessToken: aToken(validFor: const Duration(seconds: -1)),
          refreshToken: aToken(validFor: const Duration(seconds: -1)),
        ),
      );

      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });

    test("signs the user in when it cannot build the request which refreshes", () async {
      final login = aLogin(
        signedIn: AuthTokens(accessToken: aToken()),
        canBuildRefreshRequest: false,
      );
      await login.keep(_expiredWithRefresh());

      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aLoginRoute]);
    });

    test("signs the user in when the server refuses to refresh the token", () async {
      final login = aLogin(signedIn: AuthTokens(accessToken: aToken()));
      await login.keep(_expiredWithRefresh());
      server.answers[aRefreshRoute] = RequestStatus.loginError;

      await login.manageLogInWithRequest(aRequest());

      expect(server.routes, [aRefreshRoute, aLoginRoute]);
    });

    test("signs the user in when the answer of the refresh holds no token", () async {
      final login = aLogin(signedIn: AuthTokens(accessToken: aToken()));
      await login.keep(_expiredWithRefresh());

      await login.manageLogInWithRequest(aRequest());

      expect(login.parsedRefreshes, 1);
      expect(server.routes, [aRefreshRoute, aLoginRoute]);
    });

    test("refreshes nothing while the token it holds is still valid", () async {
      final login = aLogin(refreshed: AuthTokens(accessToken: aToken()));
      await login.keep(AuthTokens(accessToken: aToken(), refreshToken: aToken()));

      await login.manageLogInWithRequest(aRequest());

      expect(server.requests, isEmpty);
    });

    test("forgets everything when neither the refresh nor the sign in worked", () async {
      final login = aLogin();
      await login.keep(_expiredWithRefresh());

      final status = await login.manageLogInWithRequest(aRequest());

      expect(status, RequestStatus.globalError);
      expect(login.tokensInfo, isNull);
    });
  });
}
