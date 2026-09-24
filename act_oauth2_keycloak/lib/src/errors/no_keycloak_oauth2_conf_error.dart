// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when we don't find any Keycloak OAuth2 conf in the config files
class NoKeycloakOAuth2ConfError extends Error {
  /// Return a string representation fo the error
  @override
  String toString() =>
      "No configuration has been found in the conf files for the Keycloak OAut2 provider, or the "
      "conf is incorrect";
}
