// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This error is thrown when we don't find any Keycloak OAuth2 conf in the config files
class NoKeycloakOAuth2ConfError extends ActError {
  /// Class constructor
  NoKeycloakOAuth2ConfError()
    : super(
        "No configuration has been found in the conf files for the Keycloak OAuth2 provider, or "
        "the conf is incorrect",
      );
}
