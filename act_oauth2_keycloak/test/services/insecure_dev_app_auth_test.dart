// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_keycloak_oauth2.dart';

void main() {
  const issuer = "http://10.0.0.1:8081/realms/a-realm";

  late FakeAppAuth delegate;
  late InsecureDevAppAuth appAuth;

  setUp(() {
    delegate = FakeAppAuth();
    appAuth = InsecureDevAppAuth(delegate);
  });

  group("InsecureDevAppAuth.authorizeAndExchangeCode", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = AuthorizationTokenRequest("a-client", aRedirectUrl, issuer: issuer);

      final response = await appAuth.authorizeAndExchangeCode(request);

      expect(delegate.authorizeAndExchangeCodeRequest, same(request));
      expect(delegate.authorizeAndExchangeCodeRequest?.allowInsecureConnections, isTrue);
      expect(response, same(delegate.authorizeAndExchangeCodeResponse));
    });
  });

  group("InsecureDevAppAuth.authorize", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = AuthorizationRequest("a-client", aRedirectUrl, issuer: issuer);

      final response = await appAuth.authorize(request);

      expect(delegate.authorizeRequest, same(request));
      expect(delegate.authorizeRequest?.allowInsecureConnections, isTrue);
      expect(response, same(delegate.authorizeResponse));
    });
  });

  group("InsecureDevAppAuth.token", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = TokenRequest(
        "a-client",
        aRedirectUrl,
        issuer: issuer,
        refreshToken: "a-refresh-token",
      );

      final response = await appAuth.token(request);

      expect(delegate.tokenRequest, same(request));
      expect(delegate.tokenRequest?.allowInsecureConnections, isTrue);
      expect(response, same(delegate.tokenResponse));
    });
  });

  group("InsecureDevAppAuth.endSession", () {
    test("allows the insecure connections and delegates the request", () async {
      final request = EndSessionRequest(
        idTokenHint: "an-id-token",
        postLogoutRedirectUrl: aRedirectUrl,
        issuer: issuer,
      );

      final response = await appAuth.endSession(request);

      expect(delegate.endSessionRequest, same(request));
      expect(delegate.endSessionRequest?.allowInsecureConnections, isTrue);
      expect(response, same(delegate.endSessionResponse));
    });
  });
}
