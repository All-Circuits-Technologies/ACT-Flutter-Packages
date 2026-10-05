// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';

/// This mixin adds the configuration of the tb-extender broker.
///
/// It sits on the two configurations the authentication of such an application is made of, the
/// Keycloak realm it signs its users in against and the local storage its tokens are kept in, so
/// that one type parameter covers the three: a class which only names one of them has no broker to
/// talk to.
mixin MixinTbExtenderConf on MixinKeycloakOAuth2Conf, MixinAuthLocalStorageConf {
  /// This is the base URL of the tb-extender auth broker, the Keycloak access token is exchanged
  /// for the ThingsBoard ones at.
  ///
  /// A deployment which serves several tenants gives each one its own port, so this is the URL of
  /// the tenant of the application, and not the one of the broker.
  final authBrokerUrl = const ConfigVar<String>("auth.broker.url");
}
