// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This pseudo-class contains authentication constants used in the application.
sealed class AuthConstants {
  /// "Bearer" header value content to insert the token in request
  static const authBearer = "Bearer $tokenBearerKey";

  /// "bearer" header value content to insert the token in request
  static const authLowBearer = "bearer $tokenBearerKey";

  /// The token key in the bearer header value
  static const tokenBearerKey = "{token}";

  /// "bearer" token type
  static const bearerTokenType = "bearer";

  /// "Basic" header value content to insert the credentials in request
  static const authBasic = "Basic $credsBasicKey";

  /// The credentials key in the basic header value
  static const credsBasicKey = "{creds}";

  /// Header key for authorization
  /// This is used to pass the authentication token or credentials in HTTP requests
  static const authorizationKey = "Authorization";

  /// The separator used to split username and password in basic credentials
  /// format (e.g., "username:password")
  static const credsSeparator = ":";
}
