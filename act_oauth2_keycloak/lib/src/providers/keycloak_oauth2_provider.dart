// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_keycloak/src/errors/no_keycloak_oauth2_conf_error.dart';
import 'package:act_oauth2_keycloak/src/mixins/mixin_keycloak_oauth2_conf.dart';

/// This is the OAuth2 class to communicate to a Keycloak provider
///
/// The redirect URLs are given by the application, because a Keycloak client validates them
/// against the URLs its realm was registered with, and because the scheme they are built on
/// belongs to the application and not to this package.
class KeycloakOAuth2Provider<C extends MixinKeycloakOAuth2Conf> extends AbsOAuth2ProviderService {
  /// This is the logs category for Keycloak OAuth2 provider
  static const _logsCategory = "keycloak";

  /// This is the URL the realm sends the user back to after a sign in.
  ///
  /// It has to match, character for character, one of the redirect URIs registered on the Keycloak
  /// client: the `<scheme>:/oauthredirect` the core builds is refused by Keycloak.
  final String redirectUrl;

  /// This is the URL the realm sends the user back to after a sign out.
  ///
  /// Keycloak validates it against the registered redirect URIs as well; therefore, it is
  /// [redirectUrl] unless the application registered another one for the sign out.
  final String postLogoutRedirectUrl;

  /// Class constructor
  KeycloakOAuth2Provider({required this.redirectUrl, String? postLogoutRedirectUrl})
    : postLogoutRedirectUrl = postLogoutRedirectUrl ?? redirectUrl,
      super(logsCategory: _logsCategory);

  /// {@macro act_oauth2_google.AbsOAuth2ProviderService.getDefaultOAuth2Conf}
  @override
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf() async {
    final tmpConf = globalGetIt().get<C>().keycloakOAuth2Conf.load();
    if (tmpConf == null) {
      throw NoKeycloakOAuth2ConfError();
    }

    return tmpConf;
  }

  /// Build the URL used by the provider to redirect to the app after a sign in
  @override
  Future<String> buildRedirectUrl() async => redirectUrl;

  /// Build the URL used by the provider to redirect to the app after a sign out
  @override
  Future<String> buildPostLogoutRedirectUrl() async => postLogoutRedirectUrl;
}
