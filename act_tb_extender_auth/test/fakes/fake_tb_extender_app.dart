// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// Builds a token carrying [payload], the way Keycloak or ThingsBoard would.
///
/// The signature is not one: the package only ever reads the claims of a token.
String fakeJwt(Map<String, dynamic> payload) {
  String segment(Map<String, dynamic> content) =>
      base64Url.encode(utf8.encode(jsonEncode(content))).replaceAll("=", "");

  return "${segment({"alg": "RS256", "typ": "JWT"})}.${segment(payload)}.signature";
}

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// The configuration of an application which signs its users in through Keycloak and exchanges
/// their tokens at the broker.
class FakeTbExtenderConfig extends AbstractConfigManager
    with MixinStoresConf, MixinKeycloakOAuth2Conf, MixinAuthLocalStorageConf, MixinTbExtenderConf {
  /// Class constructor
  FakeTbExtenderConfig() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeTbExtenderConfig> withContent(String content) async {
    FakeAssets.serve({"${configPath}default.yaml": content});

    final manager = FakeTbExtenderConfig();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The properties of the application under test.
class FakeTbExtenderProperties extends AbstractPropertiesManager {}

/// The secrets of that application, which hold its two sets of tokens.
class FakeTbExtenderSecrets extends AbstractSecretsManager
    with MixinAuthSecrets, MixinKeycloakAuthSecrets {
  /// Class constructor
  FakeTbExtenderSecrets({required super.propertiesGetter, required super.confGetter});
}

/// The tokens kept in memory rather than where the platform keeps its secrets.
class FakeAuthStorage with MixinAuthStorageService {
  /// The tokens the service stored, if it stored any.
  AuthTokens? stored;

  @override
  Future<AuthTokens?> loadTokens() async => stored;

  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    stored = tokens;
    return true;
  }

  @override
  Future<void> clearTokens() async => stored = null;
}

/// The Keycloak provider of the tests, which answers what a test hands it and records what the
/// service asked of it, rather than opening a browser.
class FakeKeycloakProvider extends AbsOAuth2ProviderService {
  /// The library the service handed the provider at init, if it was initialized.
  FlutterAppAuth? receivedAppAuth;

  /// The storage the service handed the provider, if it handed one.
  MixinAuthStorageService? receivedStorage;

  /// The result the provider answers a sign in with.
  AuthSignInResult redirectResult = const AuthSignInResult(status: AuthSignInStatus.done);

  /// The Keycloak tokens the provider holds, null when its session is gone.
  AuthTokens? tokens;

  /// Whether the service ended the Keycloak session.
  bool signOutCalled = false;

  /// What the provider answers a sign out with, true when Keycloak ended its session.
  bool signOutAnswer = true;

  /// The error the provider raises on a sign out, if it raises one.
  Exception? signOutError;

  /// Whether the provider says it handed fresh tokens over when it was asked for some.
  bool refreshAnswer = true;

  /// The number of refreshes the service asked of the provider.
  int refreshCalls = 0;

  /// Class constructor
  FakeKeycloakProvider() : super(logsCategory: "fakeKeycloak");

  @override
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf() async => const DefaultOAuth2Conf(
    clientId: "a-client-id",
    issuer: "https://keycloak.example.test/realms/a-realm",
    discoveryUrl: null,
    providerUrlConf: null,
    scopes: ["openid"],
    appAuthRedirectScheme: "com.example.app",
  );

  @override
  Future<void> initProvider({
    required LogsHelper parentLogsHelper,
    required FlutterAppAuth appAuth,
  }) async => receivedAppAuth = appAuth;

  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async =>
      receivedStorage = storageService;

  @override
  Future<AuthSignInResult> redirectToExternalUserSignIn() async => redirectResult;

  @override
  Future<AuthTokens?> getTokens() async => tokens;

  @override
  Future<bool> isUserSigned() async => tokens != null;

  @override
  Future<bool> refreshTokens() async {
    refreshCalls++;
    return refreshAnswer;
  }

  @override
  Future<bool> signOut() async {
    signOutCalled = true;
    // Whatever Keycloak answers, the provider forgets its tokens: that is the contract of
    // act_oauth2_core
    tokens = null;

    if (signOutError != null) {
      throw signOutError!;
    }

    return signOutAnswer;
  }
}

/// The broker of the tests, which answers what a test hands it and records the calls it received.
class FakeBrokerClient extends TbExtenderBrokerClient {
  /// The answer the broker gives a login, the failure of an unknown error when a test gives none.
  BrokerLoginResult Function(String keycloakAccessToken)? onLogin;

  /// The number of logins the service asked of the broker.
  int loginCallCount = 0;

  /// The Keycloak token of the last call the broker received.
  String? lastToken;

  /// The error the broker answers a deletion with, null when the account is gone.
  BrokerAuthError? deleteError;

  /// The number of deletions the service asked of the broker.
  int deleteCallCount = 0;

  /// The error the broker answers a terms acceptance with, null when it recorded it.
  BrokerAuthError? acceptTermsError;

  /// The number of terms acceptances the service asked of the broker.
  int acceptTermsCallCount = 0;

  /// The version of the last terms acceptance the broker received.
  String? lastAcceptedVersion;

  /// Class constructor
  FakeBrokerClient() : super(baseUrlGetter: () => "https://broker.example.test");

  @override
  Future<BrokerLoginResult> login(String keycloakAccessToken) async {
    loginCallCount++;
    lastToken = keycloakAccessToken;

    return onLogin?.call(keycloakAccessToken) ??
        const BrokerLoginFailure(BrokerAuthError.unknown);
  }

  @override
  Future<BrokerAuthError?> deleteAccount(String keycloakAccessToken) async {
    deleteCallCount++;
    lastToken = keycloakAccessToken;

    return deleteError;
  }

  @override
  Future<BrokerAuthError?> acceptTerms(
    String keycloakAccessToken, {
    required String version,
  }) async {
    acceptTermsCallCount++;
    lastToken = keycloakAccessToken;
    lastAcceptedVersion = version;

    return acceptTermsError;
  }
}

/// The refresh of the ThingsBoard tokens, which answers what a test hands it and records its
/// calls.
class RecordingTbRefresher {
  /// The tokens the refresh answers, null when ThingsBoard refused the refresh token.
  AuthTokens? result;

  /// The number of refreshes the service asked.
  int callCount = 0;

  /// The refresh token of the last call.
  String? lastRefreshToken;

  /// Refresh the ThingsBoard tokens with the given [tbRefreshToken].
  Future<AuthTokens?> call(String tbRefreshToken) async {
    callCount++;
    lastRefreshToken = tbRefreshToken;

    return result;
  }
}
