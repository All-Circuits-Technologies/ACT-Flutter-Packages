// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This class contains the constants of the server request
sealed class ServerReqConstants {
  /// This is the Content-Type key, to add it in headers
  static const contentTypeHeader = "Content-Type";

  /// "Authorization" header key to insert token
  static const authorizationHeader = "Authorization";

  /// "X-Authorization" header key to insert token
  static const xAuthorizationHeader = "X-Authorization";

  /// This defines the timeout of a client session duration
  static const clientSessionDuration = Duration(seconds: 2);

  /// The HTTPS scheme
  static const httpsScheme = "https";

  /// The HTTP scheme
  static const httpScheme = "http";
}
