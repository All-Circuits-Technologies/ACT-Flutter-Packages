// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Contains constants for HTTP header keys and values
sealed class HeaderConstants {
  /// This is the character separator used in header values to separate multiple values
  static const headerValueSeparatorChar = ";";

  /// Separator used in header values to separate multiple values, which is more cleaner than
  /// [headerValueSeparatorChar]
  static const headerValueSeparator = "$headerValueSeparatorChar ";

  /// This is the separator between property and its value in header value
  static const propertySeparatorInHeaderValue = "=";

  /// "Bearer" token type key used in "Authorization" header
  static const authBearerKey = "Bearer";

  /// "bearer" token type key used in "Authorization" header
  static const authLowBearerKey = "bearer";

  /// "Basic" token type key used in "Authorization" header
  static const authBasicKey = "Basic";

  /// "Bearer" header value content to insert the token in request
  static const authBearer = "$authBearerKey $tokenBearerKey";

  /// "bearer" header value content to insert the token in request
  static const authLowBearer = "$authLowBearerKey $tokenBearerKey";

  /// "Basic" header value content to insert the credentials in request
  static const authBasic = "$authBasicKey $credsBasicKey";

  /// The token key in the bearer header value
  static const tokenBearerKey = "{token}";

  /// The credentials key in the basic header value
  static const credsBasicKey = "{creds}";

  /// The separator used to split username and password in basic credentials
  /// format (e.g., "username:password")
  static const credsSeparator = ":";

  /// This is the `Content-Type` key, to add it in headers
  static const contentTypeHeaderKey = "Content-Type";

  /// This is the `charset` key, to add in headers value
  static const charsetKey = "charset";

  /// This is the `utf-8` value for charset
  static const charsetUtf8Value = "utf-8";

  /// This is the `Content-Disposition` key, to add it in headers
  static const contentDispositionHeaderKey = "Content-Disposition";

  /// This is the `attachment` value for the `Content-Disposition` header
  static const contentDispositionAttachmentValue = "attachment";

  /// This is the `filename` key for the `Content-Disposition` header
  static const contentDispositionFilenameKey = "filename";

  /// This is the `filename*` key for the `Content-Disposition` header
  static const contentDispositionFilenameEncodingKey = "filename*";

  /// This is the `Origin` key, to add it in headers
  static const originHeaderKey = "Origin";

  /// This is the `Accept` key, to add it in headers
  static const acceptHeaderKey = "Accept";

  /// This is the `X-Requested-With` key, to add it in headers
  static const xRequestedWithHeaderKey = "X-Requested-With";

  /// This is the `Authorization` key, to add it in headers
  static const authorizationHeaderKey = "Authorization";

  /// This is the `X-Authorization` key, to add it in headers
  static const xAuthorizationHeaderKey = "X-Authorization";

  /// This is the `Access-Control-Allow-Origin` key, to add it in headers
  static const accessControlAllowOriginHeaderKey = "Access-Control-Allow-Origin";

  /// This is the `Access-Control-Allow-Methods` key, to add it in headers
  static const accessControlAllowMethodsHeaderKey = "Access-Control-Allow-Methods";

  /// This is the `Access-Control-Allow-Headers` key, to add it in headers
  static const accessControlAllowHeadersHeaderKey = "Access-Control-Allow-Headers";
}
