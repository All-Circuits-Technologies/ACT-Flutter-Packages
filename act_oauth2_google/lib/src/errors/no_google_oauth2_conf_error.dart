// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when we don't find any Google OAuth2 conf in the config files
class NoGoogleOAuth2ConfError extends Error {
  /// Return a string representation fo the error
  @override
  String toString() =>
      "No configuration has been found in the conf files for the Google OAut2 provider, or the "
      "conf is incorrect";
}
