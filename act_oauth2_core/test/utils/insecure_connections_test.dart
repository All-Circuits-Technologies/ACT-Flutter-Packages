// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// The configuration of a provider reached through [issuer] and [discoveryUrl].
  DefaultOAuth2Conf aConf({String? issuer, String? discoveryUrl}) => DefaultOAuth2Conf(
    clientId: "a-client",
    issuer: issuer,
    discoveryUrl: discoveryUrl,
    providerUrlConf: null,
    scopes: const ["openid"],
    appAuthRedirectScheme: "com.example.app",
  );

  /// The configuration of a provider whose endpoints are named one by one.
  DefaultOAuth2Conf aConfWithEndpoints({
    required String authorizationEndpoint,
    required String tokenEndpoint,
    String? endSessionEndpoint,
  }) => DefaultOAuth2Conf.tryToParseFromJson({
    "clientId": "a-client",
    "appAuthRedirectScheme": "com.example.app",
    "scopes": ["openid"],
    "serviceConfiguration": {
      "authorizationEndpoint": authorizationEndpoint,
      "tokenEndpoint": tokenEndpoint,
      "endSessionEndpoint": ?endSessionEndpoint,
    },
  })!;

  group("shouldAllowInsecureAppAuthConnections", () {
    test("allows them when the issuer is served over plain http", () {
      expect(
        shouldAllowInsecureAppAuthConnections(aConf(issuer: "http://10.0.0.1:8081/realms/dev")),
        isTrue,
      );
    });

    test("refuses them when the issuer is served over https", () {
      expect(
        shouldAllowInsecureAppAuthConnections(aConf(issuer: "https://keycloak.example.com/realms")),
        isFalse,
      );
    });

    test("allows them when the discovery URL is served over plain http", () {
      expect(
        shouldAllowInsecureAppAuthConnections(
          aConf(discoveryUrl: "http://10.0.0.1:8081/.well-known/openid-configuration"),
        ),
        isTrue,
      );
    });

    test("allows them when one named endpoint alone is served over plain http", () {
      expect(
        shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://keycloak.example.com/auth",
            tokenEndpoint: "http://10.0.0.1:8081/token",
          ),
        ),
        isTrue,
      );
    });

    test("allows them when the end session endpoint alone is served over plain http", () {
      expect(
        shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://keycloak.example.com/auth",
            tokenEndpoint: "https://keycloak.example.com/token",
            endSessionEndpoint: "http://10.0.0.1:8081/logout",
          ),
        ),
        isTrue,
      );
    });

    test("refuses them when every named endpoint is served over https", () {
      expect(
        shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://keycloak.example.com/auth",
            tokenEndpoint: "https://keycloak.example.com/token",
            endSessionEndpoint: "https://keycloak.example.com/logout",
          ),
        ),
        isFalse,
      );
    });

    test("refuses them when the configuration names no URL at all", () {
      expect(shouldAllowInsecureAppAuthConnections(aConf()), isFalse);
    });
  });

  group("isPlainHttpUrl", () {
    test("says so of an http URL, whatever the case of its scheme", () {
      expect(isPlainHttpUrl("http://10.0.0.1:8081"), isTrue);
      expect(isPlainHttpUrl("HTTP://10.0.0.1:8081"), isTrue);
    });

    test("says nothing of an https URL", () {
      expect(isPlainHttpUrl("https://keycloak.example.com"), isFalse);
    });

    test("says nothing of a null, an empty or a scheme-less URL", () {
      expect(isPlainHttpUrl(null), isFalse);
      expect(isPlainHttpUrl(""), isFalse);
      expect(isPlainHttpUrl("keycloak.example.com/realms"), isFalse);
    });
  });
}
