// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

sealed class AuthConstants {
  /// "Bearer" header value content to insert the token in request
  static const authBearer = "Bearer $tokenBearerKey";

  /// "bearer" header value content to insert the token in request
  static const authLowBearer = "bearer $tokenBearerKey";

  /// The token key in the bearer header value
  static const tokenBearerKey = "{token}";

  /// "bearer" token type
  static const bearerTokenType = "bearer";

  static const authBasic = "Basic $credsBasicKey";

  static const credsBasicKey = "{creds}";

  static const authorizationKey = "Authorization";

  static const credsSeparator = ":";
}
