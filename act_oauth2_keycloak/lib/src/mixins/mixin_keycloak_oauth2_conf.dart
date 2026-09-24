// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';

/// This mixin adds a config for the OAuth2 Keycloak
mixin MixinKeycloakOAuth2Conf on AbstractConfigManager {
  /// This is the configuration to communicate with the OAuth2 Keycloak provider
  ///
  /// Unlike a well known provider, a Keycloak realm is hosted by the one who runs it; therefore,
  /// the configuration has to name the issuer, the discovery URL or the endpoints one by one.
  final keycloakOAuth2Conf = const ParserConfigVar<DefaultOAuth2Conf, Map<String, dynamic>>(
    "auth.oauth2.keycloak.config",
    parser: DefaultOAuth2Conf.tryToParseFromJson,
  );
}
