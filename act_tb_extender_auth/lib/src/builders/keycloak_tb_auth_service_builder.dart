// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_tb_extender_auth/src/clients/tb_extender_broker_client.dart';
import 'package:act_tb_extender_auth/src/mixins/mixin_keycloak_auth_secrets.dart';
import 'package:act_tb_extender_auth/src/mixins/mixin_tb_extender_conf.dart';
import 'package:act_tb_extender_auth/src/services/keycloak_tb_auth_service.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';

/// Assembles the [KeycloakTbAuthService] of an application out of the managers it registered.
///
/// [KeycloakTbAuthService] is given every collaborator it works with, which is what makes it
/// testable; this is where the ones an application runs with are taken from the service locator,
/// and it is the only place of this package which reaches it. [C] is the configuration manager of
/// the application and [S] its secrets manager.
///
/// The managers it reads have to be registered by the time [build] is called, which the
/// authentication manager of an application says by naming them in the `dependsOn` of its builder:
/// the configuration manager, the secrets manager and the [TbNoAuthServerReqManager].
class KeycloakTbAuthServiceBuilder<
  C extends MixinTbExtenderConf,
  S extends MixinKeycloakAuthSecrets
> {
  /// Class constructor
  const KeycloakTbAuthServiceBuilder();

  /// Build the service of an application whose Keycloak realm sends its users back to
  /// [redirectUrl], and to [postLogoutRedirectUrl] after a sign out when the realm registered
  /// another one for it.
  ///
  /// [onSignOut] is how the application is told that a session ended, so that it forgets whatever
  /// belonged to the account which is leaving.
  ///
  /// The service is returned before its life cycle is initialized, which the caller does.
  KeycloakTbAuthService build({
    required String redirectUrl,
    String? postLogoutRedirectUrl,
    OnSignOut? onSignOut,
  }) => KeycloakTbAuthService(
    keycloakProvider: KeycloakOAuth2Provider<C>(
      redirectUrl: redirectUrl,
      postLogoutRedirectUrl: postLogoutRedirectUrl,
    ),
    brokerClient: TbExtenderBrokerClient(
      baseUrlGetter: () => globalGetIt().get<C>().authBrokerUrl.load(),
    ),
    keycloakStorageService: SecureLocalAuthStorage<C, S>(
      tokensItem: globalGetIt().get<S>().keycloakTokens,
    ),
    tbTokenRefresher: _refreshTbTokens,
    keycloakConfLoader: () => globalGetIt().get<C>().keycloakOAuth2Conf.load(),
    onSignOut: onSignOut,
  );

  /// Refresh the ThingsBoard tokens with [tbRefreshToken], against ThingsBoard itself.
  ///
  /// The request manager is what holds the ThingsBoard client, and the client is what keeps the
  /// tokens the refresh minted; therefore, they are read back from it rather than from the answer.
  ///
  /// Return null when ThingsBoard refused the refresh token.
  static Future<AuthTokens?> _refreshTbTokens(String tbRefreshToken) async {
    final reqManager = globalGetIt().get<TbNoAuthServerReqManager>();
    final response = await reqManager.request(
      (tbClient) async => tbClient.refreshJwtToken(refreshToken: tbRefreshToken),
    );

    if (!response.isOk) {
      appLogger().w("A problem occurred when refreshing the ThingsBoard token");
      return null;
    }

    return _tokensFromTbClient(reqManager);
  }

  /// Read the tokens the ThingsBoard client of [reqManager] holds.
  ///
  /// Return null when there is no access token to read, or when one of the two isn't a JWT.
  static AuthTokens? _tokensFromTbClient(TbNoAuthServerReqManager reqManager) {
    final tbClient = reqManager.tbClient;
    final accessStrToken = tbClient.getJwtToken();
    final refreshStrToken = tbClient.getRefreshToken();
    if (accessStrToken == null) {
      return null;
    }

    final accessToken = AuthToken.fromJwtToken(accessStrToken);
    if (accessToken == null) {
      return null;
    }

    AuthToken? refreshToken;
    if (refreshStrToken != null) {
      refreshToken = AuthToken.fromJwtToken(refreshStrToken);
      if (refreshToken == null) {
        return null;
      }
    }

    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }
}
