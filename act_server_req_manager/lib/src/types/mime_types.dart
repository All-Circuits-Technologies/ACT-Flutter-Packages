// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The mime types managed by this package
enum MimeTypes {
  /// No mime types
  empty(str: ""),

  /// This is a plain text mime type
  plainText(str: "text/plain"),

  /// This is a json mime types
  json(str: "application/json"),

  /// This is a form url encoded mime type
  formUrlEncoded(str: "application/x-www-form-urlencoded"),

  /// This is a multipart form data mime type
  multipartFormData(str: "multipart/form-data");

  /// Returns a string which can be added in the request headers
  final String str;

  /// Class constructor
  const MimeTypes({required this.str});
}
