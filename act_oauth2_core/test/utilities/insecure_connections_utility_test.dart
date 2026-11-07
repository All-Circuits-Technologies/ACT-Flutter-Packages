// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
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
    test("refuses them in a release build, even for a realm served over plain http", () {
      _ReleaseGlobalManager.install();

      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(issuer: "http://10.0.0.1:8081/realms/dev"),
        ),
        isFalse,
      );
    });

    test("allows them when the issuer is served over plain http", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(issuer: "http://10.0.0.1:8081/realms/dev"),
        ),
        isTrue,
      );
    });

    test("refuses them when the issuer is served over https", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(issuer: "https://auth.example.com/realms"),
        ),
        isFalse,
      );
    });

    test("allows them when the discovery URL is served over plain http", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(discoveryUrl: "http://10.0.0.1:8081/.well-known/openid-configuration"),
        ),
        isTrue,
      );
    });

    test("allows them when one named endpoint alone is served over plain http", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://auth.example.com/auth",
            tokenEndpoint: "http://10.0.0.1:8081/token",
          ),
        ),
        isTrue,
      );
    });

    test("allows them when the end session endpoint alone is served over plain http", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://auth.example.com/auth",
            tokenEndpoint: "https://auth.example.com/token",
            endSessionEndpoint: "http://10.0.0.1:8081/logout",
          ),
        ),
        isTrue,
      );
    });

    test("refuses them when every named endpoint is served over https", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConfWithEndpoints(
            authorizationEndpoint: "https://auth.example.com/auth",
            tokenEndpoint: "https://auth.example.com/token",
            endSessionEndpoint: "https://auth.example.com/logout",
          ),
        ),
        isFalse,
      );
    });

    test("refuses them when the configuration names no URL at all", () {
      expect(InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(aConf()), isFalse);
    });

    test("allows them whatever the case of the http scheme", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(issuer: "HTTP://10.0.0.1:8081/realms/dev"),
        ),
        isTrue,
      );
    });

    test("refuses them when the issuer has no scheme", () {
      expect(
        InsecureConnectionsUtility.shouldAllowInsecureAppAuthConnections(
          aConf(issuer: "auth.example.com/realms"),
        ),
        isFalse,
      );
    });
  });
}

/// A global manager which says the application runs in a release build, which a test never does.
class _ReleaseGlobalManager extends FakeGlobalManager {
  /// Says the application runs in a release build.
  @override
  bool get isReleaseMode => true;

  /// Builds a manager and sets it as the one of the application.
  static void install() => AbsGlobalManager.setInstance = _ReleaseGlobalManager();
}
