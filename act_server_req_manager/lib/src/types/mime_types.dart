// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The mime types managed by this package
enum MimeTypes {
  empty(str: ""),
  plainText(str: "text/plain"),
  json(str: "application/json"),
  formUrlEncoded(str: "application/x-www-form-urlencoded"),
  multipartFormData(str: "multipart/form-data");

  /// Returns a string which can be added in the request headers
  final String str;

  /// Class constructor
  const MimeTypes({required this.str});
}
