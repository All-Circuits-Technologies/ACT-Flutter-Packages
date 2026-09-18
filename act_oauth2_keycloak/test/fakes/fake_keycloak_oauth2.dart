// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The redirect URL the realm of an application under test is frozen on.
const aRedirectUrl = "com.example.app://oauth2redirect";

/// The configuration of an application whose users sign in with Keycloak.
const aKeycloakConf = """
auth:
  oauth2:
    keycloak:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        issuer: "https://keycloak.example.com/realms/a-realm"
        scopes:
          - openid
          - profile
""";

/// The configuration which names the Keycloak client of an application under test.
class FakeKeycloakConfigManager extends AbstractConfigManager with MixinKeycloakOAuth2Conf {
  /// Class constructor
  FakeKeycloakConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeKeycloakConfigManager> withContent(String content) async {
    FakeAssets.serve({configKey: content});

    final manager = FakeKeycloakConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The library which speaks to the provider, which records the request each call receives and
/// answers a canned response, so the wrapper can be covered without a device.
class FakeAppAuth implements FlutterAppAuth {
  /// The authorization and exchange the wrapper delegated, if it delegated one.
  AuthorizationTokenRequest? authorizeAndExchangeCodeRequest;

  /// The token request the wrapper delegated, if it delegated one.
  TokenRequest? tokenRequest;

  /// The end session request the wrapper delegated, if it delegated one.
  EndSessionRequest? endSessionRequest;

  /// The authorization the wrapper delegated, if it delegated one.
  AuthorizationRequest? authorizeRequest;

  /// The answer to an authorization and exchange.
  final authorizeAndExchangeCodeResponse = AuthorizationTokenResponse(
    "access",
    "refresh",
    null,
    "id-token",
    "Bearer",
    const <String>[],
    null,
    null,
  );

  /// The answer to a token request.
  final tokenResponse = TokenResponse(
    "access",
    "refresh",
    null,
    "id-token",
    "Bearer",
    const <String>[],
    null,
  );

  /// The answer to an end session request.
  final endSessionResponse = EndSessionResponse("a state");

  /// The answer to an authorization.
  final authorizeResponse = const AuthorizationResponse();

  /// Class constructor
  FakeAppAuth();

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorizeAndExchangeCodeRequest = request;

    return authorizeAndExchangeCodeResponse;
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    tokenRequest = request;

    return tokenResponse;
  }

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    endSessionRequest = request;

    return endSessionResponse;
  }

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    authorizeRequest = request;

    return authorizeResponse;
  }
}
