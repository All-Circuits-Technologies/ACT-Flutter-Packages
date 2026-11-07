// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_oauth2.dart';

/// The realm of a development stack, served over plain http.
const _issuer = "http://10.0.0.1:8081/realms/a-realm";

/// The URL the realm sends the user back to.
const _redirectUrl = "com.example.app://oauth2redirect";

void main() {
  late FakeAppAuth delegate;
  late InsecureDevAppAuth appAuth;

  setUp(() {
    delegate = FakeAppAuth();
    appAuth = InsecureDevAppAuth(delegate);
  });

  group("InsecureDevAppAuth.authorizeAndExchangeCode", () {
    test("allows the insecure connections and delegates the request", () async {
      delegate.authorizationAnswer = AuthorizationTokenResponse(
        "a token",
        "a refresh token",
        DateTime.now().toUtc(),
        "an id token",
        "Bearer",
        const ["openid"],
        const {},
        const {},
      );
      final request = AuthorizationTokenRequest("a-client", _redirectUrl, issuer: _issuer);

      await appAuth.authorizeAndExchangeCode(request);

      expect(delegate.authorizations.single, same(request));
      expect(request.allowInsecureConnections, isTrue);
    });
  });

  group("InsecureDevAppAuth.authorize", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = AuthorizationRequest("a-client", _redirectUrl, issuer: _issuer);

      await appAuth.authorize(request);

      expect(delegate.authorizeRequests.single, same(request));
      expect(request.allowInsecureConnections, isTrue);
    });
  });

  group("InsecureDevAppAuth.token", () {
    test("allows the insecure connections and delegates the request", () async {
      delegate.tokenAnswer = TokenResponse(
        "a token",
        null,
        DateTime.now().toUtc(),
        "an id token",
        "Bearer",
        const ["openid"],
        const {},
      );
      final request = TokenRequest(
        "a-client",
        _redirectUrl,
        issuer: _issuer,
        refreshToken: "a refresh token",
      );

      await appAuth.token(request);

      expect(delegate.tokenRequests.single, same(request));
      expect(request.allowInsecureConnections, isTrue);
    });
  });

  group("InsecureDevAppAuth.endSession", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = EndSessionRequest(
        idTokenHint: "an id token",
        postLogoutRedirectUrl: _redirectUrl,
        issuer: _issuer,
      );

      await appAuth.endSession(request);

      expect(delegate.endSessions.single, same(request));
      expect(request.allowInsecureConnections, isTrue);
    });
  });
}
